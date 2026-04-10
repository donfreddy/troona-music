import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';

/// Port (interface) between the Domain layer and the concrete audio engine.
///
/// The Domain never imports `just_audio` or `audio_service` directly.
/// [JustAudioAdapter] implements this contract.
///
/// All streams must emit an initial value immediately
/// (use a BehaviorSubject or a seeded StreamController).
abstract interface class AudioServicePort {
  // ── Streams (real-time observation) ─────────────────────────────────────────

  /// Current playback position, emitted at ~60 fps during playback.
  Stream<Duration> get positionStream;

  /// Buffered position (network / disk read-ahead).
  Stream<Duration> get bufferedPositionStream;

  /// Playback status (playing, paused, buffering, stopped).
  Stream<PlaybackStatus> get statusStream;

  /// Currently loaded track; null when nothing is loaded.
  Stream<Track?> get currentTrackStream;

  /// Duration of the current track.
  Stream<Duration> get durationStream;

  /// Full queue state.
  Stream<Queue> get queueStream;

  /// Current volume (0.0 – 1.0).
  Stream<double> get volumeStream;

  // ── Synchronous snapshots ────────────────────────────────────────────────────

  PlaybackStatus get currentStatus;
  Track? get currentTrack;
  Duration get currentPosition;
  Duration get currentDuration;
  Queue? get currentQueue;

  // ── Commands ─────────────────────────────────────────────────────────────────

  /// Loads and plays [track]. Initialises the queue when [queue] is provided.
  Future<Either<Failure, Unit>> playTrack(Track track, {Queue? queue});

  /// Pauses playback.
  Future<Either<Failure, Unit>> pause({Duration? fadeDuration});

  /// Resumes playback.
  Future<Either<Failure, Unit>> resume({Duration? fadeDuration});

  /// Seeks to [position].
  Future<Either<Failure, Unit>> seekTo(Duration position);

  /// Advances to the next track in the queue.
  Future<Either<Failure, Unit>> skipToNext();

  /// Returns to the previous track.
  Future<Either<Failure, Unit>> skipToPrevious();

  /// Replaces the queue with [tracks] and starts playback from [startIndex].
  Future<Either<Failure, Unit>> setQueue(
    List<Track> tracks, {
    int startIndex = 0,
  });

  /// Restores an exact queue snapshot, including playback order and position.
  Future<Either<Failure, Unit>> restoreQueue(
    Queue queue, {
    required Duration position,
    required bool play,
    required double volume,
    required double speed,
  });

  /// Appends [track] to the end of the queue.
  Future<Either<Failure, Unit>> addToQueue(Track track);

  /// Removes the track at [index] from the queue.
  Future<Either<Failure, Unit>> removeFromQueue(int index);

  /// Moves a queue item from [oldIndex] to [newIndex].
  Future<Either<Failure, Unit>> moveQueueItem(int oldIndex, int newIndex);

  /// Enables or disables shuffle mode.
  Future<Either<Failure, Unit>> setShuffleEnabled(bool enabled);

  /// Sets the repeat mode.
  Future<Either<Failure, Unit>> setRepeatMode(RepeatMode mode);

  /// Sets the volume (0.0 – 1.0).
  Future<Either<Failure, Unit>> setVolume(double volume);

  /// Sets the playback speed (0.5 – 2.0).
  Future<Either<Failure, Unit>> setSpeed(double speed);

  /// Stops playback and releases audio resources (does not stop the service).
  Future<void> stop();

  /// Full teardown — call only when the app is closing.
  Future<void> dispose();
}
