import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';

final class GetLikesPlaylistUseCase {
  final LibraryRepository _repo;
  const GetLikesPlaylistUseCase(this._repo);

  Future<Either<Failure, Playlist>> call() => _repo.getLikesPlaylist();
}
