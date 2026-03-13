import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/use_cases/no_params.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';

final class GetTracksUseCase {
  final LibraryRepository _repo;
  const GetTracksUseCase(this._repo);

  Future<Either<Failure, List<Track>>> call([NoParams _ = const NoParams()]) =>
      _repo.getTracks();
}
