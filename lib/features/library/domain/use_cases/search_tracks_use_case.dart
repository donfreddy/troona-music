import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';

final class SearchTracksUseCase {
  final LibraryRepository _repo;
  const SearchTracksUseCase(this._repo);

  Future<Either<Failure, List<Track>>> call(String query) => _repo.searchTracks(query);
}
