abstract interface class AudioServicePort {
  // Streams en lecture seule — le domaine observe, ne modifie pas
  Stream<Duration>       get positionStream;
  Stream<Duration>       get bufferedPositionStream;
  Stream<PlaybackStatus> get statusStream;
  Stream<Track?>         get currentTrackStream;
  Stream<Queue>          get queueStream;

  // Lecture
  Future<void> playTrack(Track track);
  Future<void> playFromQueue(int index);
  Future<void> pause();
  Future<void> resume();
  Future<void> seek(Duration position);
  Future<void> stop();

  // Navigation
  Future<void> skipToNext();
  Future<void> skipToPrevious();

  // Queue management
  Future<void> setQueue(List<Track> tracks, {int startIndex = 0});
  Future<void> addToQueue(Track track);
  Future<void> removeFromQueue(int index);
  Future<void> moveQueueItem(int oldIndex, int newIndex);
  Future<void> clearQueue();

  // Modes
  Future<void> setRepeatMode(RepeatMode mode);
  Future<void> toggleShuffle(bool enabled);

  // Lifecycle
  Future<void> init();
  Future<void> dispose();
}