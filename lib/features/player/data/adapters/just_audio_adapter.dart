import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';
import 'package:troona/features/player/domain/ports/audio_service_port.dart';

// Adapter Pattern : traduit les appels du Domain vers just_audio.
// Le Domain ne sait jamais que just_audio existe.
@LazySingleton(as: AudioServicePort)
class JustAudioAdapter implements AudioServicePort {
  final AudioPlayer _player;
  final List<AudioSource> _sources = [];

  // BehaviorSubjects = stream + valeur initiale accessible en sync
  final _queueSubject = BehaviorSubject<Queue>();
  final _volumeSubject = BehaviorSubject<double>.seeded(1.0);

  Queue? _currentQueue;

  JustAudioAdapter() : _player = AudioPlayer() {
    _initStreams();
  }

  // ── Initialisation des streams ─────────────────────────────────────────────

  void _initStreams() {
    // Écoute les changements de player pour mettre à jour la queue interne
    _player.currentIndexStream.listen((index) {
      if (_currentQueue != null && index != null) {
        _currentQueue = _currentQueue!.copyWith(currentIndex: index);
        _queueSubject.add(_currentQueue!);
      }
    });

    // Volume initial
    _volumeSubject.add(_player.volume);
  }

  // ── AudioServicePort : Streams ─────────────────────────────────────────────

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

  // ── AudioServicePort : Valeurs instantanées ────────────────────────────────

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

  // ── AudioServicePort : Commandes ───────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> playTrack(Track track, {Queue? queue}) async {
    try {
      if (queue != null) {
        return setQueue(queue.originalTracks, startIndex: queue.currentIndex);
      }
      // Track seul — crée une queue d'un élément
      _sources
        ..clear()
        ..add(AudioSource.uri(Uri.parse(track.uri), tag: track));
      await _player.setAudioSources(_sources);
      _updateQueue(Queue.single(track));
      await _player.play();
      return right(unit);
    } on PlayerException catch (e) {
      return left(PlaybackFailure(e.message ?? 'Erreur lecture: ${e.code}'));
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
        await _player.seek(Duration.zero, index: 0);
        await _player.play();
      }
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
      if (tracks.isEmpty) return left(const PlaybackFailure('Queue vide'));

      _sources
        ..clear()
        ..addAll(
          tracks.map(
            (t) => AudioSource.uri(
              Uri.parse(t.uri),
              tag: t, // stocké pour accès dans les notifications
            ),
          ),
        );

      await _player.setAudioSources(_sources, initialIndex: startIndex);

      final newQueue = Queue.fromTracks(
        tracks,
        startIndex: startIndex,
        shuffleEnabled: _currentQueue?.shuffleEnabled ?? false,
        repeatMode: _currentQueue?.repeatMode ?? RepeatMode.off,
      );
      _updateQueue(newQueue);

      await _player.play();
      return right(unit);
    } on PlayerException catch (e) {
      return left(PlaybackFailure(e.message ?? 'Erreur source audio'));
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> addToQueue(Track track) async {
    try {
      _sources.add(AudioSource.uri(Uri.parse(track.uri), tag: track));
      await _rebuildSources();
      if (_currentQueue != null) _updateQueue(_currentQueue!.addTrack(track));
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeFromQueue(int index) async {
    try {
      if (index < 0 || index >= _sources.length) {
        return left(const PlaybackFailure('Index hors limites'));
      }
      _sources.removeAt(index);
      await _rebuildSources();
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
      if (oldIndex < 0 ||
          oldIndex >= _sources.length ||
          newIndex < 0 ||
          newIndex >= _sources.length) {
        return left(const PlaybackFailure('Index hors limites'));
      }
      final item = _sources.removeAt(oldIndex);
      _sources.insert(newIndex, item);
      await _rebuildSources();
      if (_currentQueue != null) {
        _updateQueue(_currentQueue!.moveItem(oldIndex, newIndex));
      }
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> setShuffleEnabled(bool enabled) async {
    try {
      await _player.setShuffleModeEnabled(enabled);
      if (_currentQueue != null) {
        _updateQueue(_currentQueue!.toggleShuffle());
      }
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
    } catch (e) {
      return left(PlaybackFailure(e.toString()));
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

  // ── Helpers privés ─────────────────────────────────────────────────────────

  void _updateQueue(Queue queue) {
    _currentQueue = queue;
    _queueSubject.add(queue);
  }

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

  Future<void> _rebuildSources() async {
    if (_sources.isEmpty) {
      await _player.stop();
      return;
    }

    final currentIndex = _player.currentIndex ?? 0;
    final position = _player.position;
    final clampedIndex = currentIndex.clamp(0, _sources.length - 1);
    final wasPlaying = _player.playing;

    await _player.setAudioSources(
      _sources,
      initialIndex: clampedIndex,
      initialPosition: position,
    );

    if (wasPlaying) await _player.play();
  }
}
