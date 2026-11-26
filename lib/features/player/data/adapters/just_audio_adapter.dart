import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/data/adapters/gain_ramp.dart';
import 'package:troona/features/player/domain/entities/mix_settings.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';
import 'package:troona/features/player/domain/entities/track_edges.dart';
import 'package:troona/features/player/domain/ports/audio_service_port.dart';
import 'package:troona/features/player/domain/services/transition_planner.dart';

/// [AudioServicePort] implementation backed by the `just_audio` package.
///
/// Follows the **Adapter** pattern: translates domain-level commands
/// ([playTrack], [pause], [seekTo], …) into `just_audio` API calls. The rest
/// of the app never imports `just_audio` directly: only this class does.
///
/// **Queue management** uses the just_audio 0.10.x list API
/// (`setAudioSources`, `addAudioSource`, `removeAudioSourceAt`,
/// `moveAudioSource`) which mutates the internal playlist without rebuilding
/// the audio pipeline, avoiding position loss and the latency of a full
/// `setAudioSources` round-trip on every queue edit.
///
/// **Shuffle** is managed entirely in the domain [Queue] entity
/// (Fisher-Yates via [Queue.toggleShuffle]). When shuffle is toggled,
/// [setShuffleEnabled] rebuilds the player's source list in the new playback
/// order rather than delegating to `just_audio`'s internal shuffle, which
/// would conflict with our domain ordering.
///
/// **Streams** backed by [BehaviorSubject] emit an initial value immediately
/// on subscription, as required by [AudioServicePort]'s contract.
///
/// **Fades**: play and resume fade in, pause fades out before pausing, and a
/// track change by the user fades out briefly, then in. Auto-advance stays
/// gapless. The fade is a gain applied on top of the user's volume, so it
/// never shows on the volume stream or in the saved session.
///
/// **Decks**: playback runs on two players, so that a song can start under
/// the end of another (a crossfade). One deck is active: it holds the
/// queue, takes every command, and is the one the port's streams follow.
/// The other stays idle, with nothing loaded (just_audio makes no native
/// player before a first load). Volume, speed and the equalizer's trim go
/// to both, so a deck that becomes active already has them.
///
/// **Crossfade**: [prepareLead] before the next song is due, the idle deck
/// loads the queue on it, paused and silent. When the song playing passes
/// the plan's `outAt`, the idle deck starts and becomes the active one at
/// once: the queue, the screen and every command move to the song coming.
/// The deck left behind only fades out, its gain following its own
/// position, and stops at the plan's end, before its file does (it still
/// holds the queue and would move on by itself). Without a plan (crossfade
/// off, an album kept whole, repeat one, the last song), the active deck
/// moves on by itself, gapless, as without a second deck.
class JustAudioAdapter implements AudioServicePort {
  final List<_Deck> _decks;

  /// The deck that holds the queue; the streams follow it.
  late final BehaviorSubject<_Deck> _activeDeck = BehaviorSubject.seeded(
    _decks.first,
  );

  _Deck get _active => _activeDeck.value;
  AudioPlayer get _player => _active.player;
  GainRamp get _fade => _active.fade;

  /// Fade at play, resume and pause, and fade-in after a track change.
  static const fadeDuration = AudioServicePort.pauseFade;

  /// Fade-out before a track change: shorter, so a skip still feels instant.
  static const switchFadeDuration = Duration(milliseconds: 120);

  /// The user's volume; the player gets it times the fade's gain and the
  /// equalizer's [_trim].
  double _volume = 1;

  /// The equalizer's anti-clip attenuation, a factor of the volume. Like the
  /// fade, it never shows on the volume stream or in the saved session.
  double _trim = 1;

  /// Runs before each load, so the equalizer's probe is written before the
  /// platform makes the effects.
  final Future<void>? Function()? _beforeLoad;

  /// Whether playback should run. False as soon as a pause starts fading,
  /// so the status says "paused" at the tap, not once the fade is over.
  final _playIntent = BehaviorSubject<bool>.seeded(false);

  /// Bumped by every pause: only the latest one pauses the player.
  int _pauseRequest = 0;

  /// Local mirror of the domain queue. Kept in sync with the player's
  /// `currentIndexStream` and updated on every queue mutation.
  Queue? _currentQueue;

  /// BehaviorSubject for the queue so subscribers receive the latest value
  /// immediately on listen.
  final _queueSubject = BehaviorSubject<Queue>();

  /// BehaviorSubject for volume; seeded with the player's initial volume.
  final _volumeSubject = BehaviorSubject<double>.seeded(1.0);

  /// The number of decks.
  static const deckCount = 2;

  /// How long before a transition the idle deck loads the queue: loading
  /// a long queue takes a few hundred milliseconds.
  static const prepareLead = Duration(seconds: 15);

  /// A transition starts only within this much of its `outAt`, reached by
  /// playing: past it (a seek, a pause held there), the song simply ends
  /// and the next follows, gapless.
  static const startWindow = Duration(seconds: 1);

  /// How often a transition reads the song leaving's position: finer than
  /// the position stream (up to 200 ms apart), whose steps could be heard.
  /// A timer of the transition's own, cancelled with it: just_audio's
  /// `createPositionStream` keeps its timer until the player is disposed,
  /// one more for each transition.
  static const _fadeStep = Duration(milliseconds: 20);

  /// Reads the transition settings, at each step of a transition.
  final MixSettings Function() _mix;

  /// A song's edges when known, read when a transition is planned: never
  /// waited for.
  final TrackEdges? Function(Track track) _edgesOf;

  /// [players] is for tests (one per deck); the app uses the defaults, each
  /// with the effects of its entry in [audioPipelines] (the equalizer), and
  /// calls [beforeLoad] before each load (awaited when it returns a future).
  /// [mix] is read whenever a transition is planned, prepared or started;
  /// without it, songs never overlap. [edgesOf] tells where songs' music
  /// starts and stops, when known, for smart transitions.
  JustAudioAdapter({
    List<AudioPlayer>? players,
    List<AudioPipeline>? audioPipelines,
    Future<void>? Function()? beforeLoad,
    MixSettings Function()? mix,
    TrackEdges? Function(Track track)? edgesOf,
  }) : assert(players == null || players.length == deckCount),
       assert(audioPipelines == null || audioPipelines.length == deckCount),
       _decks = [],
       _beforeLoad = beforeLoad,
       _mix = mix ?? _noMix,
       _edgesOf = edgesOf ?? _noEdges {
    for (var i = 0; i < deckCount; i++) {
      final player =
          players?[i] ??
          AudioPlayer(
            handleInterruptions: false,
            maxSkipsOnError: 3,
            audioPipeline: audioPipelines?[i],
          );
      _decks.add(_Deck(player, () => _volume * _trim));
    }
    _initStreams();
  }

  /// Each deck's Android audio sessions, in deck order: the effects of a
  /// deck are made again for each new one.
  List<Stream<int?>> get androidAudioSessionIdStreams => [
    for (final deck in _decks) deck.player.androidAudioSessionIdStream,
  ];

  /// Scales the volume by [factor] (at most 1) for the equalizer's
  /// anti-clip attenuation.
  void setTrim(double factor) {
    _trim = factor.clamp(0.0, 1.0);
    for (final deck in _decks) {
      unawaited(
        deck.applyVolume().catchError((Object e, StackTrace st) {
          ErrorHandler.handle(e, st);
        }),
      );
    }
  }

  /// Makes deck [index] the active one, outside of a transition: it shows
  /// that the streams follow the active deck.
  @visibleForTesting
  void debugActivateDeck(int index) => _activeDeck.add(_decks[index]);

  static MixSettings _noMix() => MixSettings.off;

  static TrackEdges? _noEdges(Track track) => null;

  /// Whether [deck] is the active one: an idle deck's events are ignored.
  bool _isActive(_Deck deck) => identical(deck, _active);

  // ---------------------------------------------------------------------------
  // Stream initialisation
  // ---------------------------------------------------------------------------

  void _initStreams() {
    for (final deck in _decks) {
      _listenTo(deck);
    }
    _volume = _player.volume;
    _volumeSubject.add(_volume);
  }

  void _listenTo(_Deck deck) {
    // Mirror the player's current index into the domain queue so that
    // auto-advance (gapless playback) keeps _currentQueue in sync.
    deck.player.currentIndexStream.listen((index) {
      if (!_isActive(deck)) return;
      // While sources load, just_audio first re-emits the *previous* index
      // against the new sequence: mapped onto the new queue it would name a
      // track that is not playing. The loaded queue already has its index.
      if (_loadsInFlight > 0) return;
      final queue = _currentQueue;
      // Out of range: a late index of the playlist being replaced.
      if (queue == null || index == null) return;
      if (index >= queue.playbackTracks.length) return;
      _updateQueue(queue.copyWith(currentIndex: index));
    });

    // At the end of the queue just_audio completes but keeps `playing` true
    // until told to pause: the status would stay "playing", and a seek back
    // to the start would set the queue off again.
    deck.player.processingStateStream
        .where((state) => state == ProcessingState.completed)
        .where((_) => _isActive(deck))
        .listen((_) => _onQueueCompleted());

    // Read straight from each deck rather than through the active one's
    // stream: no position is lost as the decks swap.
    deck.player.positionStream
        .where((_) => _isActive(deck))
        .listen(_onPosition);
  }

  void _onQueueCompleted() {
    _playIntent.add(false);
    _fade.stop();
    unawaited(_player.pause());
  }

  // ---------------------------------------------------------------------------
  // AudioServicePort: Streams
  // ---------------------------------------------------------------------------

  /// [select]'s stream of the active deck, switching with it.
  Stream<T> _followActive<T>(Stream<T> Function(AudioPlayer player) select) =>
      _activeDeck.stream.switchMap((deck) => select(deck.player));

  @override
  Stream<Duration> get positionStream => _followActive((p) => p.positionStream);

  @override
  Stream<Duration> get bufferedPositionStream =>
      _followActive((p) => p.bufferedPositionStream);

  @override
  Stream<PlaybackStatus> get statusStream => Rx.combineLatest2(
    _followActive((p) => p.playerStateStream),
    _playIntent.stream,
    _status,
  );

  /// Derived from the queue, the source of truth for what is playing: the
  /// player index alone is not re-emitted when a new queue starts at the
  /// same index, and the lock screen would keep the old track. Emits when
  /// the current entry (index or track) changes.
  @override
  Stream<Track?> get currentTrackStream => _queueSubject.stream
      .map((q) => (q.currentIndex, q.currentTrack))
      .distinct((a, b) => a.$1 == b.$1 && a.$2?.id == b.$2?.id)
      .map((entry) => entry.$2);

  @override
  Stream<Duration> get durationStream =>
      _followActive((p) => p.durationStream).map((d) => d ?? Duration.zero);

  @override
  Stream<Queue> get queueStream => _queueSubject.stream;

  @override
  Stream<double> get volumeStream => _volumeSubject.stream;

  @override
  Stream<double> get speedStream => _followActive((p) => p.speedStream);

  @override
  Stream<Failure> get errorStream => _followActive((p) => p.errorStream).map(
    (e) =>
        PlaybackFailure(e.message ?? 'This file cannot be played (${e.code})'),
  );

  // ---------------------------------------------------------------------------
  // AudioServicePort: Synchronous accessors
  // ---------------------------------------------------------------------------

  @override
  PlaybackStatus get currentStatus =>
      _status(_player.playerState, _playIntent.value);

  @override
  Track? get currentTrack {
    final index = _player.currentIndex;
    if (index == null || _currentQueue == null) return null;
    final tracks = _currentQueue!.playbackTracks;
    if (index < 0 || index >= tracks.length) return null;
    return tracks[index];
  }

  @override
  Duration get currentPosition => _player.position;

  @override
  Duration get currentDuration => _player.duration ?? Duration.zero;

  @override
  Queue? get currentQueue => _currentQueue;

  // ---------------------------------------------------------------------------
  // AudioServicePort: Commands
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, Unit>> playTrack(Track track, {Queue? queue}) async {
    _interrupt();
    try {
      if (queue != null) {
        // When a full queue is provided, start playback at the requested index.
        return await setQueue(
          queue.originalTracks,
          startIndex: queue.currentIndex,
        );
      }
      // Single-track playback: a one-item queue.
      return await _loadQueue(
        Queue.single(track),
        () => _player.setAudioSources([_toAudioSource(track)]),
        play: true,
      );
    } on PlayerException catch (e) {
      return left(PlaybackFailure(e.message ?? 'Playback error (${e.code})'));
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  /// Fades out over [fade], then pauses. A resume during the fade cancels
  /// the pause, and of several pauses only the latest one pauses the player,
  /// once its fade is over. [Duration.zero] pauses at once, cutting any fade
  /// short.
  @override
  Future<Either<Failure, Unit>> pause({
    Duration fade = AudioServicePort.pauseFade,
  }) async {
    try {
      final request = ++_pauseRequest;
      _playIntent.add(false);
      // Both songs of a transition: their gains follow the one leaving, so
      // the transition holds still while paused.
      final decks = _sounding;
      if (fade <= Duration.zero) {
        for (final deck in decks) {
          deck.fade.stop();
        }
      } else if (_player.playing) {
        await Future.wait([for (final deck in decks) deck.fade.to(0, fade)]);
      }
      if (!_playIntent.value && request == _pauseRequest) {
        await Future.wait([for (final deck in decks) deck.player.pause()]);
      }
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> resume() async {
    try {
      await _play();
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> seekTo(Duration position) async {
    _interrupt();
    try {
      await _player.seek(position);
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> skipToNext() async {
    _interrupt();
    try {
      if (_player.hasNext) {
        await _switchTrack(_player.seekToNext);
      } else if (_currentQueue?.repeatMode == RepeatMode.all) {
        // Manual wrap-around when repeat-all is active.
        await _switchTrack(() => _player.seek(Duration.zero, index: 0));
        await _play();
      }
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> skipToIndex(int index) async {
    try {
      final queue = _currentQueue;
      if (queue == null || index < 0 || index >= queue.length) {
        return left(const PlaybackFailure('Queue index out of range'));
      }
      _interrupt();
      await _switchTrack(() => _player.seek(Duration.zero, index: index));
      await _play();
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> skipToPrevious() async {
    _interrupt();
    try {
      if (_player.hasPrevious) {
        await _switchTrack(_player.seekToPrevious);
      } else if (_currentQueue?.repeatMode == RepeatMode.all) {
        final last = (_currentQueue?.length ?? 1) - 1;
        await _switchTrack(() => _player.seek(Duration.zero, index: last));
        await _play();
      }
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> setQueue(
    List<Track> tracks, {
    int startIndex = 0,
    bool? shuffle,
  }) async {
    _interrupt();
    try {
      if (tracks.isEmpty) return left(const PlaybackFailure('Queue is empty'));

      final newQueue = Queue.fromTracks(
        tracks,
        startIndex: startIndex,
        shuffleEnabled: shuffle ?? _currentQueue?.shuffleEnabled ?? false,
        repeatMode: _currentQueue?.repeatMode ?? RepeatMode.off,
      );

      // Load sources in playback order (already shuffled if needed).
      return await _loadQueue(
        newQueue,
        () => _player.setAudioSources(
          newQueue.playbackTracks.map(_toAudioSource).toList(),
          initialIndex: newQueue.currentIndex,
        ),
        play: true,
      );
    } on PlayerException catch (e) {
      return left(PlaybackFailure(e.message ?? 'Audio source error'));
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> restoreQueue(
    Queue queue, {
    required Duration position,
    required bool play,
    required double volume,
    required double speed,
  }) async {
    _interrupt();
    try {
      if (queue.playbackTracks.isEmpty) {
        return left(const PlaybackFailure('Queue is empty'));
      }

      final nextVolume = volume.clamp(0.0, 1.0);
      final nextSpeed = speed.clamp(0.5, 2.0);

      final loaded = await _loadQueue(
        queue,
        () => _player.setAudioSources(
          queue.playbackTracks.map(_toAudioSource).toList(),
          initialIndex: queue.currentIndex,
          initialPosition: position,
        ),
      );
      // After the load, not inside it: the sources are in, so a failure
      // here must not roll the queue back.
      await _player.setLoopMode(_mapRepeatMode(queue.repeatMode));
      _volume = nextVolume;
      await _applyVolumes();
      await _setSpeeds(nextSpeed);
      _volumeSubject.add(nextVolume);
      if (play) await _play();
      return loaded;
    } on PlayerException catch (e) {
      return left(PlaybackFailure(e.message ?? 'Audio source error'));
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  // just_audio 0.10.x: edit the playlist without a full reload.
  @override
  Future<Either<Failure, Unit>> addToQueue(Track track, {int? index}) =>
      index == null
      ? _editQueue(
          (queue) => queue.addTrack(track),
          () => _player.addAudioSource(_toAudioSource(track)),
        )
      : _editQueue(
          (queue) => queue.insertAt(index, track),
          () => _player.insertAudioSource(index, _toAudioSource(track)),
        );

  @override
  Future<Either<Failure, Unit>> addAllToQueue(
    List<Track> tracks, {
    int? index,
  }) {
    final sources = [for (final track in tracks) _toAudioSource(track)];
    return index == null
        ? _editQueue(
            (queue) => queue.insertAllAt(queue.playbackTracks.length, tracks),
            () => _player.addAudioSources(sources),
          )
        : _editQueue(
            (queue) => queue.insertAllAt(index, tracks),
            () => _player.insertAudioSources(index, sources),
          );
  }

  @override
  Future<Either<Failure, Unit>> removeFromQueue(int index) => _editQueue(
    (queue) => queue.removeAt(index),
    () => _player.removeAudioSourceAt(index),
  );

  @override
  Future<Either<Failure, Unit>> moveQueueItem(int oldIndex, int newIndex) =>
      _editQueue(
        (queue) => queue.moveItem(oldIndex, newIndex),
        () => _player.moveAudioSource(oldIndex, newIndex),
      );

  /// Bumped by every load: a load that a newer one interrupted must not
  /// touch the queue any more.
  int _loadGeneration = 0;

  /// Loads in progress; the index listener stands down meanwhile.
  int _loadsInFlight = 0;

  /// The player call of the latest load, to wait for it.
  Future<void>? _latestLoad;

  /// Publishes [queue] *before* [load] replaces the player's sources, so
  /// that nothing reads the new player state against the old queue (the
  /// lock screen, the bloc, the play history). The previous queue is
  /// restored if loading fails; errors go to the caller's handler.
  ///
  /// With no previous queue (cold start) there is nothing stale to guard
  /// against: the queue is published once loaded, so a failed first load
  /// leaves no queue behind.
  ///
  /// With [play], the track playing fades out before the load and the new
  /// one fades in.
  Future<Either<Failure, Unit>> _loadQueue(
    Queue queue,
    Future<void> Function() load, {
    bool play = false,
  }) async {
    _busy++;
    try {
      // Awaited only while the hook has something to wait for (the first
      // load of a launch): the extra turn would let a queue edit asked for
      // in the same turn land on the old queue.
      if (_beforeLoad?.call() case final pending?) await pending;
      if (play && _audible) await _fade.to(0, switchFadeDuration);
      final generation = ++_loadGeneration;
      final previous = _currentQueue;
      if (previous != null) _updateQueue(queue);
      _loadsInFlight++;
      try {
        await (_latestLoad = load());
      } catch (_) {
        if (generation == _loadGeneration && previous != null) {
          _updateQueue(previous);
        }
        rethrow;
      } finally {
        _loadsInFlight--;
      }
      if (generation != _loadGeneration) return right(unit);
      if (previous == null) _updateQueue(queue);
      if (play) await _play();
      return right(unit);
    } finally {
      _busy--;
    }
  }

  bool get _audible => _player.playing && _playIntent.value;

  /// Starts playback, or takes it back from a pause still fading out, and
  /// fades in. Starting from silence: the gain is zeroed first.
  Future<void> _play() async {
    _playIntent.add(true);
    for (final deck in _sounding) {
      if (!deck.player.playing) {
        await deck.fade.jump(0);
        _playInBackground(deck.player);
      }
      _fadeIn(deck);
    }
  }

  /// Runs [change] between a short fade-out and a fade-in, so a track
  /// change by the user does not cut. Paused, it only runs [change].
  Future<void> _switchTrack(Future<void> Function() change) async {
    _busy++;
    try {
      if (_audible) await _fade.to(0, switchFadeDuration);
      await change();
      if (_playIntent.value) _fadeIn();
    } finally {
      _busy--;
    }
  }

  /// Not awaited: the caller would wait for the whole fade.
  void _fadeIn([_Deck? deck]) => unawaited(
    (deck ?? _active).fade
        .to(1, fadeDuration)
        .then<void>(
          (_) {},
          onError: (Object e, StackTrace st) {
            ErrorHandler.handle(e, st);
          },
        ),
  );

  /// play() only completes once playback pauses or ends: awaiting it would
  /// keep the caller (and the bloc's droppable handlers) busy for the whole
  /// track. Its errors also reach the playback event stream.
  void _playInBackground(AudioPlayer player) => unawaited(
    player.play().catchError((Object e, StackTrace st) {
      ErrorHandler.handle(e, st);
    }),
  );

  /// Applies [edit] to the domain queue *before* mutating the player.
  ///
  /// A move or removal can shift the player's current index, and the index
  /// listener maps it onto [_currentQueue]: updated first, that mapping
  /// always sees the new order instead of reporting a phantom track change.
  /// If the player rejects the edit, see [_rollBackEdit].
  Future<Either<Failure, Unit>> _editQueue(
    Queue Function(Queue queue) edit,
    Future<void> Function() apply,
  ) async {
    final previous = _currentQueue;
    final generation = _loadGeneration;
    var edited = false;
    try {
      if (previous != null) {
        _updateQueue(edit(previous));
        edited = true;
      }
      await apply();
      return right(unit);
    } catch (e, st) {
      final failure = ErrorHandler.handle(e, st);
      if (edited) await _rollBackEdit(previous!, generation);
      return left(failure);
    }
  }

  /// Reloads the player with the track order of [previous], keeping what
  /// changed while the edit was pending: the repeat mode, the current track
  /// and its position.
  ///
  /// A reload, not just a queue update: just_audio edits its own playlist
  /// before the platform call and does not undo it when that call fails,
  /// so its sources match neither queue any more.
  ///
  /// The current index is the platform's, which still has the order of
  /// [previous]. Not [AudioPlayer.currentIndex]: just_audio clamps it to
  /// its own shortened playlist (a removal while the last track plays).
  ///
  /// A load in flight (the edit then applies to its queue) is waited for:
  /// interrupting it would fail its caller and skip its playback start.
  /// A load since [generation] (shuffle toggled, new queue) rebuilt the
  /// sources from the edited queue: they already match it, and nothing is
  /// rolled back.
  Future<void> _rollBackEdit(Queue previous, int generation) async {
    while (_loadsInFlight > 0 && generation == _loadGeneration) {
      await _latestLoad?.then((_) {}, onError: (_) {});
    }
    if (generation != _loadGeneration) return;
    final index = _player.playbackEvent.currentIndex;
    final restored = previous.copyWith(
      currentIndex: index != null && index < previous.playbackTracks.length
          ? index
          : null,
      repeatMode: _currentQueue?.repeatMode,
    );
    final position = _player.position;
    final reload = _loadGeneration + 1;
    try {
      await _loadQueue(
        restored,
        () => _player.setAudioSources(
          restored.playbackTracks.map(_toAudioSource).toList(),
          initialIndex: restored.currentIndex,
          initialPosition: position,
        ),
      );
    } catch (e, st) {
      // just_audio took the restored sources before failing to load them:
      // keep the queue that matches them, not the edited one put back by
      // [_loadQueue].
      if (reload == _loadGeneration) _updateQueue(restored);
      ErrorHandler.handle(e, st);
    }
  }

  /// Toggles shuffle on or off.
  ///
  /// Shuffle is managed entirely by the domain [Queue] entity (Fisher-Yates).
  /// When the state actually changes, the player's source list is rebuilt in
  /// the new playback order at the current position so no audio glitch occurs.
  @override
  Future<Either<Failure, Unit>> setShuffleEnabled(bool enabled) async {
    try {
      if (_currentQueue == null) return right(unit);
      // No-op when the requested state equals the current state.
      if (enabled == _currentQueue!.shuffleEnabled) return right(unit);

      final position = _player.position;
      final newQueue = _currentQueue!.toggleShuffle();

      // Rebuild sources in the new playback order, restoring position.
      return await _loadQueue(
        newQueue,
        () => _player.setAudioSources(
          newQueue.playbackTracks.map(_toAudioSource).toList(),
          initialIndex: newQueue.currentIndex,
          initialPosition: position,
        ),
      );
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> setRepeatMode(RepeatMode mode) async {
    try {
      await _player.setLoopMode(_mapRepeatMode(mode));
      if (_currentQueue != null) {
        _updateQueue(_currentQueue!.setRepeatMode(mode));
      }
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> setVolume(double volume) async {
    try {
      _volume = volume;
      await _applyVolumes();
      _volumeSubject.add(volume);
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> setSpeed(double speed) async {
    try {
      await _setSpeeds(speed);
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<void> stop() {
    _playIntent.add(false);
    _interrupt(fadeOut: Duration.zero);
    _fade.stop();
    return _player.stop();
  }

  @override
  Future<void> dispose() async {
    _interrupt(fadeOut: Duration.zero);
    for (final deck in _decks) {
      deck.fade.stop();
    }
    await _playIntent.close();
    await _queueSubject.close();
    await _volumeSubject.close();
    await _activeDeck.close();
    for (final deck in _decks) {
      await deck.player.dispose();
    }
  }

  /// Sends every deck its volume: the user's, the trim, its own fade.
  Future<void> _applyVolumes() => _onEveryDeck((deck) => deck.applyVolume());

  Future<void> _setSpeeds(double speed) =>
      _onEveryDeck((deck) => deck.player.setSpeed(speed));

  /// Runs [call] on every deck and waits for the active one: an idle deck
  /// that fails is logged, never the user's command failing.
  Future<void> _onEveryDeck(Future<void> Function(_Deck deck) call) {
    final active = _active;
    for (final deck in _decks) {
      if (identical(deck, active)) continue;
      unawaited(
        call(deck).catchError((Object e, StackTrace st) {
          ErrorHandler.handle(e, st);
        }),
      );
    }
    return call(active);
  }

  // ---------------------------------------------------------------------------
  // Crossfade
  // ---------------------------------------------------------------------------

  /// The transition under way, being prepared, prepared or fading; null
  /// between two.
  _Transition? _transition;

  /// Bumped whenever a transition ends or is dropped: a preparation it
  /// outlived must not set itself up.
  int _mixGeneration = 0;

  /// The queue whose preparation failed: not tried again until what a
  /// transition depends on changes in it ([_sameForTransition]).
  Queue? _unpreparable;

  /// Loads and track changes in progress: no transition is prepared or
  /// started meanwhile, or it would swap the decks under the command.
  int _busy = 0;

  _Deck get _idle => _decks.firstWhere((deck) => !_isActive(deck));

  /// The decks that make sound: the active one, and the one a transition
  /// is fading out.
  List<_Deck> get _sounding => [
    _active,
    if (_transition case _Transition(stage: _Stage.fading, :final leaving))
      leaving,
  ];

  void _onPosition(Duration position) {
    if (_transition != null || _loadsInFlight > 0 || _busy > 0) return;
    final queue = _currentQueue;
    if (queue == null) return;
    if (_unpreparable case final failed?
        when _sameForTransition(queue, failed)) {
      return;
    }
    final settings = _mix();
    if (!settings.crossfade) return;
    var plan = _planFor(queue, settings);
    // Edges found late may put the start behind the position: the plan
    // without them still fades, rather than none.
    if (plan != null && settings.smart && position >= plan.outAt) {
      plan = _planFor(queue, settings, edges: false);
    }
    if (plan == null) return;
    if (position < plan.outAt - prepareLead || position >= plan.outAt) return;
    unawaited(_prepare(queue, plan));
  }

  /// How the next song of [queue] comes in; null when it simply follows.
  TransitionPlan? _planFor(
    Queue queue,
    MixSettings settings, {
    bool edges = true,
  }) {
    if (queue.repeatMode == RepeatMode.one) return null;
    final current = queue.currentTrack;
    final index = _nextIndexOf(queue);
    final length = _player.duration;
    if (current == null || index == null || length == null) return null;
    final next = queue.playbackTracks[index];
    return TransitionPlanner.plan(
      current: current,
      length: length,
      next: next,
      settings: settings,
      currentEdges: edges && settings.smart ? _edgesOf(current) : null,
      nextEdges: edges && settings.smart ? _edgesOf(next) : null,
    );
  }

  /// The index of the song after the current one, wrapping under repeat
  /// all; null when none, or when it is the same song.
  int? _nextIndexOf(Queue queue) {
    final index = queue.currentIndex + 1 < queue.length
        ? queue.currentIndex + 1
        : queue.repeatMode == RepeatMode.all
        ? 0
        : null;
    return index == queue.currentIndex ? null : index;
  }

  /// Loads [queue] on the idle deck at the next song, paused and silent,
  /// then follows the active deck closely until the transition is due.
  Future<void> _prepare(Queue queue, TransitionPlan plan) async {
    final coming = _idle;
    final transition = _transition = _Transition(
      queue: queue,
      plan: plan,
      nextIndex: _nextIndexOf(queue)!,
      leaving: _active,
      coming: coming,
    );
    final generation = _mixGeneration;
    try {
      // A deck faded out by the transition before may still be stopping.
      await coming.released;
      if (generation != _mixGeneration) return;
      await coming.setMix(0);
      if (generation != _mixGeneration) return;
      await coming.player.setLoopMode(_mapRepeatMode(queue.repeatMode));
      if (generation != _mixGeneration) return;
      await coming.player.setAudioSources(
        queue.playbackTracks.map(_toAudioSource).toList(),
        initialIndex: transition.nextIndex,
        initialPosition: plan.inFrom,
      );
    } catch (e, st) {
      if (generation != _mixGeneration) return;
      ErrorHandler.handle(e, st);
      _unpreparable = queue;
      _dropTransition();
      return;
    }
    if (generation != _mixGeneration) {
      // Dropped while loading: release the deck, unless a newer
      // transition took it meanwhile.
      if (!identical(_transition?.coming, coming)) _release(coming);
      return;
    }
    transition
      ..stage = _Stage.prepared
      ..ticker = Timer.periodic(
        _fadeStep,
        (_) => _onTransitionPosition(transition.leaving.player.position),
      );
  }

  /// [position] is the song leaving's: it starts the transition, then
  /// drives both gains, then ends it.
  void _onTransitionPosition(Duration position) {
    final transition = _transition;
    if (transition == null) return;
    final plan = transition.plan;
    switch (transition.stage) {
      case _Stage.preparing:
        return;
      case _Stage.prepared:
        if (position < plan.outAt) return;
        if (position >= plan.outAt + startWindow) return _dropTransition();
        // Paused there, or a command under way: wait, the window still
        // open.
        if (!_playIntent.value || !transition.leaving.player.playing) return;
        if (_busy > 0) return;
        if (!_mix().crossfade) return _dropTransition();
        _startTransition(transition);
      case _Stage.fading:
        final (leaving, coming) = plan.gainsAt(position);
        _logged(transition.leaving.setMix(leaving));
        _logged(transition.coming.setMix(coming));
        if (position >= plan.end) _finishTransition();
    }
  }

  /// Starts the song coming and makes its deck the active one: the queue,
  /// the screen and every command move to it.
  void _startTransition(_Transition transition) {
    transition.stage = _Stage.fading;
    final leaving = transition.leaving;
    final coming = transition.coming;
    _logged(coming.fade.jump(1));
    _playInBackground(coming.player);
    _activeDeck.add(coming);
    _updateQueue(_currentQueue!.copyWith(currentIndex: transition.nextIndex));
    // The deck leaving still holds the queue: should it move on or end by
    // itself, it stops at once. Both streams replay their value on listen.
    final index = leaving.player.currentIndex;
    transition
      ..listen(
        leaving.player.currentIndexStream
            .where((i) => i != index)
            .listen((_) => _finishTransition()),
      )
      ..listen(
        leaving.player.processingStateStream
            .where((state) => state == ProcessingState.completed)
            .listen((_) => _finishTransition()),
      );
  }

  /// Ends the transition under way: the song coming takes its full volume,
  /// the one leaving fades out over [fadeOut] (it is down to nothing at
  /// the plan's end), then stops, releasing its decoder.
  void _finishTransition({Duration fadeOut = Duration.zero}) {
    final transition = _transition;
    if (transition == null || transition.stage != _Stage.fading) return;
    _transition = null;
    _mixGeneration++;
    transition.cancel();
    _logged(transition.coming.setMix(1));
    // Its mix stays where the transition left it: idle, it is silent, and
    // the next preparation sets it again.
    final leaving = transition.leaving;
    leaving.released = leaving.released
        .then((_) async {
          if (fadeOut > Duration.zero && leaving.player.playing) {
            await leaving.fade.to(0, fadeOut);
          }
          await leaving.player.stop();
        })
        .catchError((Object e, StackTrace st) {
          ErrorHandler.handle(e, st);
        });
  }

  /// Drops a transition that has not started: its deck, silent, stops.
  void _dropTransition() {
    final transition = _transition;
    if (transition == null || transition.stage == _Stage.fading) return;
    _transition = null;
    _mixGeneration++;
    transition.cancel();
    _release(transition.coming);
  }

  /// Stops [deck] once what it was doing is over: chained, so a stop
  /// still pending never lands on a load that came after it.
  void _release(_Deck deck) {
    deck.released = deck.released.then((_) => deck.player.stop()).catchError((
      Object e,
      StackTrace st,
    ) {
      ErrorHandler.handle(e, st);
    });
  }

  /// Whether [a] and [b] lead to the same transition: the same songs in
  /// the same order, the same one playing, the same repeat mode. just_audio
  /// reports the index again on every playback event (a pause, a play,
  /// buffering), and each one republishes the queue unchanged.
  static bool _sameForTransition(Queue a, Queue b) {
    if (identical(a, b)) return true;
    if (a.currentIndex != b.currentIndex ||
        a.repeatMode != b.repeatMode ||
        a.playbackTracks.length != b.playbackTracks.length) {
      return false;
    }
    for (var i = 0; i < a.playbackTracks.length; i++) {
      if (a.playbackTracks[i].id != b.playbackTracks[i].id) return false;
    }
    return true;
  }

  /// Ends any transition before a command that changes what plays: the
  /// song leaving goes out over [fadeOut], one being prepared is dropped.
  void _interrupt({Duration fadeOut = switchFadeDuration}) {
    switch (_transition?.stage) {
      case null:
        return;
      case _Stage.fading:
        _finishTransition(fadeOut: fadeOut);
      case _Stage.preparing || _Stage.prepared:
        _dropTransition();
    }
  }

  void _logged(Future<void> call) => unawaited(
    call.catchError((Object e, StackTrace st) {
      ErrorHandler.handle(e, st);
    }),
  );

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Publishes [queue]. A transition prepared for the queue before is
  /// dropped: its next song may not be the next any more. One under way
  /// carries on, its song leaving no longer part of the queue.
  void _updateQueue(Queue queue) {
    if (_transition case _Transition(
      stage: != _Stage.fading,
      queue: final prepared,
    ) when !_sameForTransition(queue, prepared)) {
      _dropTransition();
    }
    _currentQueue = queue;
    _queueSubject.add(queue);
  }

  /// Builds an [AudioSource] from a [Track].
  ///
  /// Prefers the content URI (MediaStore on Android) when available and falls
  /// back to the absolute file path when the URI is empty.
  AudioSource _toAudioSource(Track track) => AudioSource.uri(
    track.uri.isNotEmpty ? Uri.parse(track.uri) : Uri.file(track.path),
    tag: track,
  );

  /// Still playing but asked to pause: the pause is fading out.
  PlaybackStatus _status(PlayerState state, bool playIntent) =>
      state.playing &&
          !playIntent &&
          state.processingState != ProcessingState.completed
      ? PlaybackStatus.paused
      : _mapState(state);

  PlaybackStatus _mapState(PlayerState state) {
    // Before `playing`: a completed queue may still report playing.
    if (state.processingState == ProcessingState.completed) {
      return PlaybackStatus.stopped;
    }
    if (state.processingState == ProcessingState.loading ||
        state.processingState == ProcessingState.buffering) {
      return PlaybackStatus.buffering;
    }
    if (state.playing) return PlaybackStatus.playing;
    return PlaybackStatus.paused;
  }

  LoopMode _mapRepeatMode(RepeatMode mode) => switch (mode) {
    RepeatMode.off => LoopMode.off,
    RepeatMode.all => LoopMode.all,
    RepeatMode.one => LoopMode.one,
  };
}

/// One of the adapter's players, with its own fades.
final class _Deck {
  _Deck(this.player, double Function() level) : _level = level {
    fade = GainRamp((gain) => player.setVolume(_level() * gain * mix));
  }

  final AudioPlayer player;

  /// The volume before this deck's fades: the user's, times the trim.
  final double Function() _level;

  /// Fade at play, resume and pause, and after a track change.
  late final GainRamp fade;

  /// This deck's share of a transition: 1 outside of one.
  double mix = 1;

  /// Done once a transition that used this deck has let it go.
  Future<void> released = Future.value();

  Future<void> applyVolume() => player.setVolume(_level() * fade.gain * mix);

  Future<void> setMix(double gain) {
    mix = gain;
    return applyVolume();
  }
}

enum _Stage { preparing, prepared, fading }

/// The next song coming in on the idle deck, under the end of the one
/// playing.
final class _Transition {
  _Transition({
    required this.queue,
    required this.plan,
    required this.nextIndex,
    required this.leaving,
    required this.coming,
  });

  /// The queue it was prepared for.
  final Queue queue;
  final TransitionPlan plan;

  /// The index of the song coming, in [queue].
  final int nextIndex;

  /// The deck playing when it was prepared, and the one loaded for it.
  final _Deck leaving;
  final _Deck coming;

  _Stage stage = _Stage.preparing;

  /// Reads the song leaving's position, once prepared.
  Timer? ticker;

  final _subscriptions = <StreamSubscription<Object?>>[];

  void listen(StreamSubscription<Object?> subscription) =>
      _subscriptions.add(subscription);

  void cancel() {
    ticker?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
  }
}
