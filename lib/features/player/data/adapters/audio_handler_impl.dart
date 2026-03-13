final class AudioHandlerImpl extends BaseAudioHandler
    with QueueHandler, SeekHandler {

  final AudioServicePort _adapter;

  AudioHandlerImpl(this._adapter) {
    // Relaie les streams de l'adapter vers audio_service
    _adapter.currentTrackStream.listen((track) {
      if (track == null) return;
      mediaItem.add(MediaItem(
        id:     track.id,
        title:  track.title,
        artist: track.artist,
        duration: Duration(milliseconds: track.durationMs),
      ));
    });

    _adapter.statusStream.listen((status) {
      playbackState.add(playbackState.value.copyWith(
        playing: status == PlaybackStatus.playing,
        processingState: _mapStatus(status),
        controls: [
          MediaControl.skipToPrevious,
          status == PlaybackStatus.playing
              ? MediaControl.pause
              : MediaControl.play,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: const [0, 1, 2],
      ));
    });
  }

  // Contrôles depuis lockscreen / headphones / CarPlay
  @override Future<void> play()         async => _adapter.resume();
  @override Future<void> pause()        async => _adapter.pause();
  @override Future<void> stop()         async => _adapter.stop();
  @override Future<void> skipToNext()   async => _adapter.skipToNext();
  @override Future<void> skipToPrevious() async => _adapter.skipToPrevious();
  @override Future<void> seek(Duration pos) async => _adapter.seek(pos);

  AudioProcessingState _mapStatus(PlaybackStatus s) =>
      switch (s) {
        PlaybackStatus.loading   => AudioProcessingState.loading,
        PlaybackStatus.buffering => AudioProcessingState.buffering,
        PlaybackStatus.playing   => AudioProcessingState.ready,
        PlaybackStatus.paused    => AudioProcessingState.ready,
        PlaybackStatus.completed => AudioProcessingState.completed,
        PlaybackStatus.idle      => AudioProcessingState.idle,
      };
}
