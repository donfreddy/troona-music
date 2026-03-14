import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';

final class GetAlbumsUseCase {
  final LibraryRepository _repo;
  const GetAlbumsUseCase(this._repo);

  Future<Either<Failure, List<Album>>> call() => _repo.getAlbums();
}
