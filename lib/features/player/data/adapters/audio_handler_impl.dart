// Pont entre audio_service (lockscreen/notifications) et JustAudioAdapter.
// Délègue toutes les commandes à l'Adapter — pas de logique ici.

import 'package:audio_service/audio_service.dart';
import 'package:injectable/injectable.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart' show RepeatMode;
import 'package:troona/features/player/domain/ports/audio_service_port.dart';

@lazySingleton
class AudioHandlerImpl extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioServicePort _port;

  AudioHandlerImpl(this._port) {
    // Transmet les états de lecture à audio_service
    _port.statusStream.listen((status) {
      playbackState.add(
        playbackState.value.copyWith(
          playing: status.name == 'playing',
          processingState: _mapStatus(status.name),
          controls: _buildControls(),
          systemActions: const {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward},
        ),
      );
    });

    // Transmet le track courant aux métadonnées de notification
    _port.currentTrackStream.listen((track) {
      if (track != null) {
        mediaItem.add(_trackToMediaItem(track));
      }
    });

    // Transmet la position
    _port.positionStream.listen((pos) {
      playbackState.add(playbackState.value.copyWith(updatePosition: pos));
    });

    // Queue
    _port.queueStream.listen((q) {
      queue.add(q.playbackTracks.map(_trackToMediaItem).toList());
    });
  }

  // ── BaseAudioHandler overrides ─────────────────────────────────────────────

  @override
  Future<void> play() => _port.resume();

  @override
  Future<void> pause() => _port.pause();

  @override
  Future<void> stop() => _port.stop();

  @override
  Future<void> seek(Duration position) => _port.seekTo(position);

  @override
  Future<void> skipToNext() => _port.skipToNext();

  @override
  Future<void> skipToPrevious() => _port.skipToPrevious();

  @override
  Future<void> skipToQueueItem(int index) async {
    final q = _port.currentQueue;
    if (q == null || index < 0 || index >= q.length) return;
    final track = q.playbackTracks[index];
    await _port.playTrack(track);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) => _port.setShuffleEnabled(
    shuffleMode == AudioServiceShuffleMode.all || shuffleMode == AudioServiceShuffleMode.group,
  );

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) => _port.setRepeatMode(switch (repeatMode) {
    AudioServiceRepeatMode.none => RepeatMode.off,
    AudioServiceRepeatMode.one => RepeatMode.one,
    AudioServiceRepeatMode.all => RepeatMode.all,
    AudioServiceRepeatMode.group => RepeatMode.all,
  });

  // ── Helpers privés ─────────────────────────────────────────────────────────

  MediaItem _trackToMediaItem(Track track) => MediaItem(
    id: track.id,
    title: track.title,
    artist: track.artist,
    album: track.album,
    duration: Duration(milliseconds: track.durationMs),
    artUri: track.artworkPath != null ? Uri.parse(track.artworkPath!) : null,
    extras: {'uri': track.uri},
  );

  AudioProcessingState _mapStatus(String statusName) => switch (statusName) {
    'buffering' => AudioProcessingState.buffering,
    'playing' => AudioProcessingState.ready,
    'paused' => AudioProcessingState.ready,
    'stopped' => AudioProcessingState.idle,
    _ => AudioProcessingState.idle,
  };

  List<MediaControl> _buildControls() => [
    MediaControl.skipToPrevious,
    MediaControl.pause,
    MediaControl.play,
    MediaControl.skipToNext,
  ];
}
