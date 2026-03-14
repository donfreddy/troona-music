import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';

final class IsTrackInLikesUseCase {
  final LibraryRepository _repo;
  const IsTrackInLikesUseCase(this._repo);

  Future<Either<Failure, bool>> call(String trackId) =>
      _repo.isTrackInLikes(trackId);
}
