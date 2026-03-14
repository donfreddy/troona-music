import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';

final class RemoveTrackFromLikesUseCase {
  final LibraryRepository _repo;
  const RemoveTrackFromLikesUseCase(this._repo);

  Future<Either<Failure, Unit>> call(String trackId) =>
      _repo.removeTrackFromLikes(trackId);
}
