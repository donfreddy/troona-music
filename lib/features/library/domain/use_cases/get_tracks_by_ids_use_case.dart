import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';

final class GetTracksByIdsUseCase {
  final LibraryRepository _repo;
  const GetTracksByIdsUseCase(this._repo);

  Future<Either<Failure, List<Track>>> call(List<String> ids) =>
      _repo.getTracksByIds(ids);
}
