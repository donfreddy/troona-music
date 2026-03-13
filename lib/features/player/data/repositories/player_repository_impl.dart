import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';
import 'package:troona/features/player/domain/ports/audio_service_port.dart';
import 'package:troona/features/player/domain/repositories/player_repository.dart';

@LazySingleton(as: PlayerRepository)
class PlayerRepositoryImpl implements PlayerRepository {
  final AudioServicePort _port;
  const PlayerRepositoryImpl(this._port);

  // ── Streams ────────────────────────────────────────────────────────────────

  @override
  Stream<Duration> get positionStream => _port.positionStream;

  @override
  Stream<Duration> get bufferedPositionStream => _port.bufferedPositionStream;

  @override
  Stream<PlaybackStatus> get statusStream => _port.statusStream;

  @override
  Stream<Track?> get currentTrackStream => _port.currentTrackStream;

  @override
  Stream<Duration> get durationStream => _port.durationStream;

  @override
  Stream<Queue> get queueStream => _port.queueStream;

  @override
  Stream<double> get volumeStream => _port.volumeStream;

  // ── Commandes ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> playTrack(Track track, {Queue? queue}) => _port.playTrack(track, queue: queue);

  @override
  Future<Either<Failure, Unit>> pause() => _port.pause();

  @override
  Future<Either<Failure, Unit>> resume() => _port.resume();

  @override
  Future<Either<Failure, Unit>> seekTo(Duration position) => _port.seekTo(position);

  @override
  Future<Either<Failure, Unit>> skipToNext() => _port.skipToNext();

  @override
  Future<Either<Failure, Unit>> skipToPrevious() => _port.skipToPrevious();

  @override
  Future<Either<Failure, Unit>> setQueue(List<Track> tracks, {int startIndex = 0}) =>
      _port.setQueue(tracks, startIndex: startIndex);

  @override
  Future<Either<Failure, Unit>> addToQueue(Track track) => _port.addToQueue(track);

  @override
  Future<Either<Failure, Unit>> removeFromQueue(int index) => _port.removeFromQueue(index);

  @override
  Future<Either<Failure, Unit>> moveQueueItem(int oldIndex, int newIndex) => _port.moveQueueItem(oldIndex, newIndex);

  @override
  Future<Either<Failure, Unit>> setShuffleEnabled(bool enabled) => _port.setShuffleEnabled(enabled);

  @override
  Future<Either<Failure, Unit>> setRepeatMode(RepeatMode mode) => _port.setRepeatMode(mode);

  @override
  Future<Either<Failure, Unit>> setVolume(double volume) => _port.setVolume(volume);

  @override
  Future<Either<Failure, Unit>> setSpeed(double speed) => _port.setSpeed(speed);
}
