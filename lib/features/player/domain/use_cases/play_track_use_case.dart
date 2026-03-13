import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/repositories/player_repository.dart';

class PlayTrackParams {
  final Track track;
  final Queue? queue;
  const PlayTrackParams({required this.track, this.queue});
}

@lazySingleton
class PlayTrackUseCase {
  final PlayerRepository _repo;
  const PlayTrackUseCase(this._repo);

  Future<Either<Failure, Unit>> call(PlayTrackParams params) => _repo.playTrack(params.track, queue: params.queue);
}
