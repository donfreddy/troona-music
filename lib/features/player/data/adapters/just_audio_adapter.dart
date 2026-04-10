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
/// of the app never imports `just_audio` directly — only this class does.
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
/// on subscription — required by [AudioServicePort]'s contract.
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

  int _fadeVersion = 0;

  JustAudioAdapter() : _player = AudioPlayer(handleInterruptions: false) {
    _initStreams();
  }

  /// Applies user playback preferences that affect the underlying player.
  void applySettings(AppSettings settings) {
    final crossfade = settings.crossfadeEnabled
        ? Duration(milliseconds: settings.crossfadeDurationMs)
        : Duration.zero;
    // just_audio API naming differs across versions; try both dynamically.
    final dynamic p = _player;
    try {
      p.setCrossfadeDuration(crossfade);
    } catch (_) {
      try {
        p.setCrossFadeDuration(crossfade);
      } catch (_) {
        // Crossfade not supported on this platform/version — ignore.
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
      if (_currentQueue != null && index != null) {
        _currentQueue = _currentQueue!.copyWith(currentIndex: index);
        _queueSubject.add(_currentQueue!);
      }
    });

    _volumeSubject.add(_player.volume);
  }

  // ---------------------------------------------------------------------------
  // AudioServicePort — Streams
  // ---------------------------------------------------------------------------

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  @override
  Stream<PlaybackStatus> get statusStream =>
      _player.playerStateStream.map(_mapState);

  @override
  Stream<Track?> get currentTrackStream =>
      _player.currentIndexStream.map((index) {
        if (index == null || _currentQueue == null) return null;
        final tracks = _currentQueue!.playbackTracks;
        if (index < 0 || index >= tracks.length) return null;
        return tracks[index];
      });

  @override
  Stream<Duration> get durationStream =>
      _player.durationStream.map((d) => d ?? Duration.zero);

  @override
  Stream<Queue> get queueStream => _queueSubject.stream;

  @override
  Stream<double> get volumeStream => _volumeSubject.stream;

  // ---------------------------------------------------------------------------
  // AudioServicePort — Synchronous accessors
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
  // AudioServicePort — Commands
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, Unit>> playTrack(Track track, {Queue? queue}) async {
    try {
      if (queue != null) {
        // When a full queue is provided, start playback at the requested index.
        return setQueue(queue.originalTracks, startIndex: queue.currentIndex);
      }
      // Single-track playback — create a one-item queue.
      await _player.setAudioSources([_toAudioSource(track)]);
      _updateQueue(Queue.single(track));
      await _player.play();
      return right(unit);
    } on PlayerException catch (e) {
      return left(PlaybackFailure(e.message ?? 'Playback error (${e.code})'));
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> pause({Duration? fadeDuration}) async {
    try {
      if (fadeDuration != null && fadeDuration > Duration.zero) {
        final targetVolume = _volumeSubject.value;
        final completed = await _fade(
          _player.volume,
          0.0,
          fadeDuration,
          updateSubject: false,
        );
        if (completed) {
          await _player.pause();
          await _player.setVolume(targetVolume);
          _volumeSubject.add(targetVolume);
        }
      } else {
        await _player.pause();
      }
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> resume({Duration? fadeDuration}) async {
    try {
      if (fadeDuration != null && fadeDuration > Duration.zero) {
        final targetVolume = _volumeSubject.value;
        await _player.setVolume(0.0);
        await _player.play();
        await _fade(0.0, targetVolume, fadeDuration);
      } else {
        await _player.play();
      }
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
      final isPlaying = _player.playing;
      final targetVolume = _volumeSubject.value;

      if (isPlaying) {
        final completed = await _fade(
          _player.volume, 0.0,
          const Duration(milliseconds: 80),
          updateSubject: false,
        );
        if (!completed) return right(unit);
      }

      if (_player.hasNext) {
        await _player.seekToNext();
      } else if (_currentQueue?.repeatMode == RepeatMode.all) {
        // Manual wrap-around when repeat-all is active.
        await _player.seek(Duration.zero, index: 0);
        await _player.play();
      }

      if (isPlaying) {
        await _fade(
          0.0,
          targetVolume,
          const Duration(milliseconds: 120),
          updateSubject: false,
        );
      }
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> skipToPrevious() async {
    try {
      final isPlaying = _player.playing;
      final targetVolume = _volumeSubject.value;

      if (isPlaying) {
        final completed = await _fade(
          _player.volume, 0.0,
          const Duration(milliseconds: 80),
          updateSubject: false,
        );
        if (!completed) return right(unit);
      }

      if (_player.hasPrevious) {
        await _player.seekToPrevious();
      } else if (_currentQueue?.repeatMode == RepeatMode.all) {
        final last = (_currentQueue?.length ?? 1) - 1;
        await _player.seek(Duration.zero, index: last);
        await _player.play();
      }

      if (isPlaying) {
        await _fade(
          0.0,
          targetVolume,
          const Duration(milliseconds: 120),
          updateSubject: false,
        );
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
      await _player.setAudioSources(
        newQueue.playbackTracks.map(_toAudioSource).toList(),
        initialIndex: newQueue.currentIndex,
      );
      _updateQueue(newQueue);
      await _player.play();
      return right(unit);
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

      await _player.setAudioSources(
        queue.playbackTracks.map(_toAudioSource).toList(),
        initialIndex: queue.currentIndex,
        initialPosition: position,
      );
      await _player.setLoopMode(_mapRepeatMode(queue.repeatMode));
      await _player.setVolume(nextVolume);
      await _player.setSpeed(nextSpeed);
      _volumeSubject.add(nextVolume);
      _updateQueue(queue);

      if (play) {
        await _player.play();
      }

      return right(unit);
    } on PlayerException catch (e) {
      return left(PlaybackFailure(e.message ?? 'Audio source error'));
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> addToQueue(Track track) async {
    try {
      // just_audio 0.10.x: mutate the playlist without a full reload.
      await _player.addAudioSource(_toAudioSource(track));
      if (_currentQueue != null) _updateQueue(_currentQueue!.addTrack(track));
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeFromQueue(int index) async {
    try {
      await _player.removeAudioSourceAt(index);
      if (_currentQueue != null) _updateQueue(_currentQueue!.removeAt(index));
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> moveQueueItem(
    int oldIndex,
    int newIndex,
  ) async {
    try {
      await _player.moveAudioSource(oldIndex, newIndex);
      if (_currentQueue != null) {
        _updateQueue(_currentQueue!.moveItem(oldIndex, newIndex));
      }
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
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
      await _player.setAudioSources(
        newQueue.playbackTracks.map(_toAudioSource).toList(),
        initialIndex: newQueue.currentIndex,
        initialPosition: position,
      );
      _updateQueue(newQueue);
      return right(unit);
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

  Future<bool> _fade(
    double from,
    double to,
    Duration duration, {
    bool updateSubject = true,
  }) async {
    final version = ++_fadeVersion;
    final steps = 10;
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);
    final stepValue = (to - from) / steps;

    for (var i = 1; i <= steps; i++) {
      await Future.delayed(stepDuration);
      if (_fadeVersion != version) return false;

      final newVolume = (from + stepValue * i).clamp(0.0, 1.0);
      await _player.setVolume(newVolume);
    }
    if (updateSubject) {
      _volumeSubject.add(to);
    }
    return true;
  }

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
