import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';
import 'package:troona/features/player/domain/ports/audio_service_port.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';

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
class JustAudioAdapter implements AudioServicePort {
  final AudioPlayer _player;

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
    : _player = player ?? AudioPlayer(handleInterruptions: false) {
    _initStreams();
  }

  /// Applies user playback preferences that affect the underlying player.
  void applySettings(AppSettings settings) {
    // final crossfade = settings.crossfadeEnabled
    //     ? Duration(milliseconds: settings.crossfadeDurationMs)
    //     : Duration.zero;
    // just_audio API naming differs across versions; try both dynamically.
    // final dynamic p = _player;
    try {
      // p.setCrossfadeDuration(crossfade);
    } catch (_) {
      try {
        // p.setCrossFadeDuration(crossfade);
      } catch (_) {
        // Crossfade not supported on this platform/version: ignore.
      }
    }
    // Gapless is default when crossfade is zero; nothing else to configure.
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

    _volumeSubject.add(_player.volume);
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
      _player.playerStateStream.map(_mapState);

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

  // ---------------------------------------------------------------------------
  // AudioServicePort: Synchronous accessors
  // ---------------------------------------------------------------------------

  @override
  PlaybackStatus get currentStatus => _mapState(_player.playerState);

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

  @override
  Future<Either<Failure, Unit>> pause() async {
    try {
      await _player.pause();
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> resume() async {
    try {
      await _player.play();
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
        await _player.seekToNext();
      } else if (_currentQueue?.repeatMode == RepeatMode.all) {
        // Manual wrap-around when repeat-all is active.
        await _player.seek(Duration.zero, index: 0);
        await _player.play();
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
      await _player.seek(Duration.zero, index: index);
      // Not awaited: play() only completes once playback pauses or ends,
      // which would block the caller for the whole track.
      unawaited(_player.play());
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> skipToPrevious() async {
    try {
      if (_player.hasPrevious) {
        await _player.seekToPrevious();
      } else if (_currentQueue?.repeatMode == RepeatMode.all) {
        final last = (_currentQueue?.length ?? 1) - 1;
        await _player.seek(Duration.zero, index: last);
        await _player.play();
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
  }) async {
    try {
      if (tracks.isEmpty) return left(const PlaybackFailure('Queue is empty'));

      final newQueue = Queue.fromTracks(
        tracks,
        startIndex: startIndex,
        shuffleEnabled: _currentQueue?.shuffleEnabled ?? false,
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
      await _player.setVolume(nextVolume);
      await _player.setSpeed(nextSpeed);
      _volumeSubject.add(nextVolume);
      if (play) _playInBackground();
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

  /// Publishes [queue] *before* [load] replaces the player's sources, so
  /// that nothing reads the new player state against the old queue (the
  /// lock screen, the bloc, the play history). The previous queue is
  /// restored if loading fails; errors go to the caller's handler.
  ///
  /// With no previous queue (cold start) there is nothing stale to guard
  /// against: the queue is published once loaded, so a failed first load
  /// leaves no queue behind.
  Future<Either<Failure, Unit>> _loadQueue(
    Queue queue,
    Future<void> Function() load, {
    bool play = false,
  }) async {
    final generation = ++_loadGeneration;
    final previous = _currentQueue;
    if (previous != null) _updateQueue(queue);
    _loadsInFlight++;
    try {
      await load();
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
    if (play) _playInBackground();
    return right(unit);
  }

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
    if (previous != null) _updateQueue(edit(previous));
    try {
      await apply();
      return right(unit);
    } catch (e, st) {
      if (previous != null) _rollBackEdit(previous, generation);
      return left(ErrorHandler.handle(e, st));
    }
  }

  /// Puts back the track order of [previous], the one the player still has,
  /// keeping what changed while the edit was pending: the repeat mode and
  /// the current index (read from the player, whose sources match
  /// [previous] again).
  ///
  /// A load since [generation] (shuffle toggled, new queue) rebuilt the
  /// player's sources from the edited queue: the queue already matches
  /// them and stays as it is.
  void _rollBackEdit(Queue previous, int generation) {
    if (generation != _loadGeneration) return;
    final index = _player.currentIndex;
    _updateQueue(
      previous.copyWith(
        currentIndex: index != null && index < previous.playbackTracks.length
            ? index
            : null,
        repeatMode: _currentQueue?.repeatMode,
      ),
    );
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
      await _player.setVolume(volume);
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
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() async {
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
