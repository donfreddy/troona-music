import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';

abstract interface class PlayerRepository {
  Stream<Duration> get positionStream;
  Stream<Duration> get bufferedPositionStream;
  Stream<PlaybackStatus> get statusStream;
  Stream<Track?> get currentTrackStream;
  Stream<Duration> get durationStream;
  Stream<Queue> get queueStream;
  Stream<double> get volumeStream;

  Future<Either<Failure, Unit>> playTrack(Track track, {Queue? queue});
  Future<Either<Failure, Unit>> pause({Duration? fadeDuration});
  Future<Either<Failure, Unit>> resume({Duration? fadeDuration});
  Future<Either<Failure, Unit>> seekTo(Duration position);
  Future<Either<Failure, Unit>> skipToNext();
  Future<Either<Failure, Unit>> skipToPrevious();
  Future<Either<Failure, Unit>> setQueue(List<Track> tracks, {int startIndex});
  Future<Either<Failure, Unit>> addToQueue(Track track);
  Future<Either<Failure, Unit>> removeFromQueue(int index);
  Future<Either<Failure, Unit>> moveQueueItem(int oldIndex, int newIndex);
  Future<Either<Failure, Unit>> setShuffleEnabled(bool enabled);
  Future<Either<Failure, Unit>> setRepeatMode(RepeatMode mode);
  Future<Either<Failure, Unit>> setVolume(double volume);
  Future<Either<Failure, Unit>> setSpeed(double speed);
}
