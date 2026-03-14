import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';

final class GetArtistsUseCase {
  final LibraryRepository _repo;
  const GetArtistsUseCase(this._repo);

  Future<Either<Failure, List<Artist>>> call() => _repo.getArtists();
}
