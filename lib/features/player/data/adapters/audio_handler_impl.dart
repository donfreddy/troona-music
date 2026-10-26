// Bridge between audio_service (lock screen / notification controls) and
// JustAudioAdapter. Delegates every command to the adapter; no business
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
/// All [BaseAudioHandler] overrides delegate to [_port]; state is owned by
/// [JustAudioAdapter] and surfaced via streams.
class AudioHandlerImpl extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioServicePort _port;

  AudioHandlerImpl(this._port) {
    // Forward playback status to the audio_service playback state stream.
    // Position is snapshotted here (not per tick) so the OS extrapolates.
    _port.statusStream.listen((status) {
      final playing = status.name == 'playing';
      playbackState.add(
        playbackState.value.copyWith(
          playing: playing,
          processingState: _mapStatus(status.name),
          updatePosition: _port.currentPosition,
          controls: _buildControls(playing),
          androidCompactActionIndices: const [0, 1, 2],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
        ),
      );
    });

    // Forward the current track to the OS media-item metadata stream. An
    // automatic advance keeps the status at "playing", so the position is
    // re-anchored here too.
    _port.currentTrackStream.listen((track) {
      if (track == null) return;
      mediaItem.add(_trackToMediaItem(track));
      playbackState.add(
        playbackState.value.copyWith(
          updatePosition: _port.currentPosition,
          queueIndex: _port.currentQueue?.currentIndex,
        ),
      );
    });

    // Forward the queue so the OS notification can show track count. Any
    // playback state push resets the anchor time, so the position goes with
    // it, and an edit that leaves the index alone pushes nothing.
    _port.queueStream.listen((q) {
      queue.add(q.playbackTracks.map(_trackToMediaItem).toList());
      if (q.currentIndex == playbackState.value.queueIndex) return;
      playbackState.add(
        playbackState.value.copyWith(
          queueIndex: q.currentIndex,
          updatePosition: _port.currentPosition,
        ),
      );
    });

    // The OS extrapolates the position from the last snapshot. Only a jump
    // away from that estimate (a seek made in the app) needs a new one, so
    // regular ticks are not forwarded.
    _port.positionStream.listen((position) {
      final drift = position - playbackState.value.position;
      if (drift.abs() > _maxDrift) {
        playbackState.add(
          playbackState.value.copyWith(updatePosition: position),
        );
      }
    });
  }

  static const _maxDrift = Duration(seconds: 2);

  // ---------------------------------------------------------------------------
  // BaseAudioHandler overrides: all delegate to _port
  // ---------------------------------------------------------------------------

  @override
  Future<void> play() => _port.resume();

  @override
  Future<void> pause() => _port.pause();

  @override
  Future<void> stop() async {
    await _port.stop();
    playbackState.add(
      playbackState.value.copyWith(processingState: AudioProcessingState.idle),
    );
  }

  @override
  Future<void> seek(Duration position) async {
    await _port.seekTo(position);
    playbackState.add(playbackState.value.copyWith(updatePosition: position));
  }

  @override
  Future<void> skipToNext() => _port.skipToNext();

  @override
  Future<void> skipToPrevious() => _port.skipToPrevious();

  @override
  Future<void> skipToQueueItem(int index) async {
    // Jump within the queue: playTrack would rebuild it (and reshuffle).
    await _port.skipToIndex(index);
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
  List<MediaControl> _buildControls(bool playing) => [
    MediaControl.skipToPrevious,
    if (playing) MediaControl.pause else MediaControl.play,
    MediaControl.skipToNext,
  ];
}
