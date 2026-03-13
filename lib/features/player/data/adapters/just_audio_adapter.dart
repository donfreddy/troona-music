import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:troona/features/player/domain/entities/queue_manager.dart';

final class JustAudioAdapter implements AudioServicePort {
  final AudioPlayer _player;
  final QueueManager _queueManager;
  final StreamController<Queue> _queueController = StreamController<Queue>.broadcast();

  JustAudioAdapter({AudioPlayer? player, QueueManager? queueManager})
    : _player = player ?? AudioPlayer(),
      _queueManager = queueManager ?? QueueManager();

  // ── Streams exposés ──────────────────────────────────────

  @override
  Stream<Duration> get positionStream => _player.positionStream;
  @override
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  @override
  Stream<PlaybackStatus> get statusStream => _player.playerStateStream.map(_mapPlayerState);
  @override
  Stream<Track?> get currentTrackStream => _queueController.stream.map((q) => q.currentTrack);
  @override
  Stream<Queue> get queueStream => _queueController.stream;

  // ── Init & lifecycle ─────────────────────────────────────

  @override
  Future<void> init() async {
    // Écoute la fin naturelle d'un track pour auto-skip
    _player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        await skipToNext();
      }
    });
  }

  // ── Lecture ──────────────────────────────────────────────

  @override
  Future<void> playTrack(Track track) async {
    final source = _buildAudioSource(track);
    await _player.setAudioSource(source);
    await _player.play();
    _emitQueue();
  }

  @override
  Future<void> playFromQueue(int index) async {
    final track = _queueManager.jumpTo(index);
    if (track == null) return;
    await playTrack(track);
  }

  @override
  Future<void> pause() async => _player.pause();
  @override
  Future<void> resume() async => _player.play();
  @override
  Future<void> seek(Duration pos) async => _player.seek(pos);
  @override
  Future<void> stop() async {
    await _player.stop();
    _emitQueue();
  }

  // ── Navigation dans la queue ─────────────────────────────

  @override
  Future<void> skipToNext() async {
    if (_queueManager.repeatMode == RepeatMode.one) {
      await _player.seek(Duration.zero);
      await _player.play();
      return;
    }
    final next = _queueManager.moveToNext();
    if (next != null) {
      await playTrack(next);
    } else {
      // Fin de queue sans repeat → pause + retour au début
      await _player.pause();
      await _player.seek(Duration.zero);
      _queueManager.jumpTo(0);
      _emitQueue();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    // Convention Apple : < 3s → track précédent, sinon → seek(0)
    final position = _player.position;
    if (position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    final prev = _queueManager.moveToPrevious();
    if (prev != null) await playTrack(prev);
  }

  // ── Queue management ─────────────────────────────────────

  @override
  Future<void> setQueue(List<Track> tracks, {int startIndex = 0}) async {
    _queueManager.setTracks(tracks, startIndex: startIndex);
    final track = _queueManager.currentTrack;
    if (track != null) await playTrack(track);
    _emitQueue();
  }

  @override
  Future<void> addToQueue(Track track) async {
    _queueManager.addTrack(track);
    _emitQueue();
  }

  @override
  Future<void> removeFromQueue(int index) async {
    final wasCurrentTrack = index == _queueManager.currentIndex;
    _queueManager.removeAt(index);

    // Si on supprime le track en cours, on joue le suivant
    if (wasCurrentTrack) {
      final next = _queueManager.currentTrack;
      if (next != null) {
        await playTrack(next);
      } else {
        await stop();
      }
    }
    _emitQueue();
  }

  @override
  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    _queueManager.moveItem(oldIndex, newIndex);
    _emitQueue();
  }

  @override
  Future<void> clearQueue() async {
    await stop();
    _queueManager.setTracks([]);
    _emitQueue();
  }

  // ── Modes ────────────────────────────────────────────────

  @override
  Future<void> setRepeatMode(RepeatMode mode) async {
    _queueManager._repeatMode = mode;
    // Sync just_audio pour le loop natif (RepeatOne seulement)
    await _player.setLoopMode(mode == RepeatMode.one ? LoopMode.one : LoopMode.off);
    _emitQueue();
  }

  @override
  Future<void> toggleShuffle(bool enabled) async {
    _queueManager.setShuffle(enabled);
    _emitQueue();
  }

  // ── Helpers privés ───────────────────────────────────────

  AudioSource _buildAudioSource(Track track) => AudioSource.uri(
    Uri.file(track.path),
    tag: MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      album: track.album,
      artUri: track.artworkPath != null ? Uri.file(track.artworkPath!) : null,
    ),
  );

  PlaybackStatus _mapPlayerState(PlayerState state) => switch (state.processingState) {
    ProcessingState.loading => PlaybackStatus.loading,
    ProcessingState.buffering => PlaybackStatus.buffering,
    ProcessingState.ready => state.playing ? PlaybackStatus.playing : PlaybackStatus.paused,
    ProcessingState.completed => PlaybackStatus.completed,
    ProcessingState.idle => PlaybackStatus.idle,
  };

  void _emitQueue() => _queueController.add(_queueManager.toQueue());

  @override
  Future<void> dispose() async {
    await _queueController.close();
    await _player.dispose();
  }
}
