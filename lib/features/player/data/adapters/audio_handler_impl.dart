// Bridge between audio_service (lock screen / notification controls) and
// JustAudioAdapter. Delegates every command to the adapter — no business
// logic lives here.

import 'package:audio_service/audio_service.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart'
    show RepeatMode;
import 'package:troona/features/player/domain/ports/audio_service_port.dart';

/// [BaseAudioHandler] implementation that bridges [AudioServicePort] to the
/// `audio_service` package for lock-screen controls and OS media notifications.
///
/// **Lifecycle**: instantiated once inside [AudioServiceInitializer.init] and
/// NOT registered in the DI container. The [AudioServicePort] adapter
/// ([JustAudioAdapter]) is what gets injected elsewhere.
///
/// All [BaseAudioHandler] overrides delegate to [_port] — state is owned by
/// [JustAudioAdapter] and surfaced via streams.
class AudioHandlerImpl extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioServicePort _port;

  AudioHandlerImpl(this._port) {
    // Forward playback status to the audio_service playback state stream.
    _port.statusStream.listen((status) {
      playbackState.add(
        playbackState.value.copyWith(
          playing: status.name == 'playing',
          processingState: _mapStatus(status.name),
          controls: _buildControls(),
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
        ),
      );
    });

    // Forward the current track to the OS media-item metadata stream.
    _port.currentTrackStream.listen((track) {
      if (track != null) mediaItem.add(_trackToMediaItem(track));
    });

    // Forward position so the lock-screen scrubber stays in sync.
    _port.positionStream.listen((pos) {
      playbackState.add(playbackState.value.copyWith(updatePosition: pos));
    });

    // Forward the queue so the OS notification can show track count.
    _port.queueStream.listen((q) {
      queue.add(q.playbackTracks.map(_trackToMediaItem).toList());
    });
  }

  // ---------------------------------------------------------------------------
  // BaseAudioHandler overrides — all delegate to _port
  // ---------------------------------------------------------------------------

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
    await _port.playTrack(q.playbackTracks[index]);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) =>
      _port.setShuffleEnabled(
        shuffleMode == AudioServiceShuffleMode.all ||
            shuffleMode == AudioServiceShuffleMode.group,
      );

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) =>
      _port.setRepeatMode(switch (repeatMode) {
        AudioServiceRepeatMode.none => RepeatMode.off,
        AudioServiceRepeatMode.one => RepeatMode.one,
        AudioServiceRepeatMode.all => RepeatMode.all,
        AudioServiceRepeatMode.group => RepeatMode.all,
      });

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  MediaItem _trackToMediaItem(Track track) => MediaItem(
    id: track.id,
    title: track.title,
    artist: track.artist,
    album: track.album,
    duration: Duration(milliseconds: track.durationMs),
    // Use Uri.file for local paths instead of Uri.parse to avoid encoding issues.
    artUri: track.artworkPath != null ? Uri.file(track.artworkPath!) : null,
    extras: {'uri': track.uri},
  );

  AudioProcessingState _mapStatus(String statusName) => switch (statusName) {
    'buffering' => AudioProcessingState.buffering,
    'playing' => AudioProcessingState.ready,
    'paused' => AudioProcessingState.ready,
    'stopped' => AudioProcessingState.idle,
    _ => AudioProcessingState.idle,
  };

  /// Returns the media controls shown in the OS notification.
  List<MediaControl> _buildControls() => const [
    MediaControl.skipToPrevious,
    MediaControl.pause,
    MediaControl.play,
    MediaControl.skipToNext,
  ];
}
