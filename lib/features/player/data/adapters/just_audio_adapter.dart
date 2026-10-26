import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/data/adapters/gain_ramp.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';
import 'package:troona/features/player/domain/ports/audio_service_port.dart';

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
class JustAudioAdapter implements AudioServicePort {
  final AudioPlayer _player;

  /// Fade at play, resume and pause, and fade-in after a track change.
  static const fadeDuration = Duration(milliseconds: 300);

  /// Fade-out before a track change: shorter, so a skip still feels instant.
  static const switchFadeDuration = Duration(milliseconds: 120);

  /// The user's volume; the player gets it times the fade's gain.
  double _volume = 1;

  late final _fade = GainRamp((gain) => _player.setVolume(_volume * gain));

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

  /// [player] is for tests; the app uses the default.
  JustAudioAdapter({AudioPlayer? player})
    : _player =
          player ??
          AudioPlayer(handleInterruptions: false, maxSkipsOnError: 3) {
    _initStreams();
  }

  // ---------------------------------------------------------------------------
  // Stream initialisation
  // ---------------------------------------------------------------------------

  void _initStreams() {
    // Mirror the player's current index into the domain queue so that
    // auto-advance (gapless playback) keeps _currentQueue in sync.
    _player.currentIndexStream.listen((index) {
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

    _volume = _player.volume;
    _volumeSubject.add(_volume);
  }

  // ---------------------------------------------------------------------------
  // AudioServicePort: Streams
  // ---------------------------------------------------------------------------

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  @override
  Stream<PlaybackStatus> get statusStream =>
      Rx.combineLatest2(_player.playerStateStream, _playIntent.stream, _status);

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
      _player.durationStream.map((d) => d ?? Duration.zero);

  @override
  Stream<Queue> get queueStream => _queueSubject.stream;

  @override
  Stream<double> get volumeStream => _volumeSubject.stream;

  @override
  Stream<double> get speedStream => _player.speedStream;

  @override
  Stream<Failure> get errorStream => _player.errorStream.map(
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

  /// Fades out, then pauses. A resume during the fade cancels the pause,
  /// and of several pauses only the latest one pauses the player, once its
  /// fade is over. Without [fade], pauses at once, cutting any fade short.
  @override
  Future<Either<Failure, Unit>> pause({bool fade = true}) async {
    try {
      final request = ++_pauseRequest;
      _playIntent.add(false);
      if (!fade) {
        _fade.stop();
      } else if (_player.playing) {
        await _fade.to(0, fadeDuration);
      }
      if (!_playIntent.value && request == _pauseRequest) {
        await _player.pause();
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
    try {
      await _player.seek(position);
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> skipToNext() async {
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
      await _switchTrack(() => _player.seek(Duration.zero, index: index));
      await _play();
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> skipToPrevious() async {
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
      await _player.setVolume(nextVolume * _fade.gain);
      await _player.setSpeed(nextSpeed);
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
  }

  bool get _audible => _player.playing && _playIntent.value;

  /// Starts playback, or takes it back from a pause still fading out, and
  /// fades in. Starting from silence: the gain is zeroed first.
  Future<void> _play() async {
    _playIntent.add(true);
    if (!_player.playing) {
      await _fade.jump(0);
      _playInBackground();
    }
    _fadeIn();
  }

  /// Runs [change] between a short fade-out and a fade-in, so a track
  /// change by the user does not cut. Paused, it only runs [change].
  Future<void> _switchTrack(Future<void> Function() change) async {
    if (_audible) await _fade.to(0, switchFadeDuration);
    await change();
    if (_playIntent.value) _fadeIn();
  }

  /// Not awaited: the caller would wait for the whole fade.
  void _fadeIn() => unawaited(
    _fade
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
  void _playInBackground() => unawaited(
    _player.play().catchError((Object e, StackTrace st) {
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
      await _player.setVolume(volume * _fade.gain);
      _volumeSubject.add(volume);
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> setSpeed(double speed) async {
    try {
      await _player.setSpeed(speed);
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<void> stop() {
    _playIntent.add(false);
    _fade.stop();
    return _player.stop();
  }

  @override
  Future<void> dispose() async {
    _fade.stop();
    await _playIntent.close();
    await _queueSubject.close();
    await _volumeSubject.close();
    await _player.dispose();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _updateQueue(Queue queue) {
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
      state.playing && !playIntent ? PlaybackStatus.paused : _mapState(state);

  PlaybackStatus _mapState(PlayerState state) {
    if (state.processingState == ProcessingState.loading ||
        state.processingState == ProcessingState.buffering) {
      return PlaybackStatus.buffering;
    }
    if (state.playing) return PlaybackStatus.playing;
    if (state.processingState == ProcessingState.completed) {
      return PlaybackStatus.stopped;
    }
    return PlaybackStatus.paused;
  }

  LoopMode _mapRepeatMode(RepeatMode mode) => switch (mode) {
    RepeatMode.off => LoopMode.off,
    RepeatMode.all => LoopMode.all,
    RepeatMode.one => LoopMode.one,
  };
}
