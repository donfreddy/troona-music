import 'package:troona/features/library/domain/entities/track.dart';

/// The last playback session, as the media controls offer it back while
/// nothing is loaded (Android media resumption, a headset play button).
abstract interface class ResumableSession {
  /// The track the last session stopped on; null when there is none.
  Future<Track?> lastTrack();

  /// Loads the last session and plays it. Does nothing without one.
  Future<void> resume();
}
