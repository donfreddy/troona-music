import 'package:dartz/dartz.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/artist_albums.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/artist_detail_repository.dart';
import 'package:troona/features/library/domain/services/library_grouping.dart';

final class ArtistDetailRepositoryImpl implements ArtistDetailRepository {
  final IsarLibraryDataSource _cache;

  const ArtistDetailRepositoryImpl({required IsarLibraryDataSource cache})
    : _cache = cache;

  @override
  Future<Either<Failure, Artist>> getArtistById(String id) async {
    try {
      final targetId = int.tryParse(id);
      if (targetId == null) {
        return left(const DatabaseFailure('Invalid artist ID format'));
      }

      final tracks = await _cache.getTracksByArtistId(targetId);
      final artist = LibraryGrouping.artistOf(targetId, [
        for (final t in tracks) t.toEntity(),
      ]);
      if (artist == null) {
        return left(const DatabaseFailure('Artist not found'));
      }
      return right(artist);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, List<Track>>> getTopTracksByArtistId(String id) async {
    try {
      final targetId = int.tryParse(id);
      if (targetId == null) {
        return left(const DatabaseFailure('Invalid ID format'));
      }

      // Every song that credits this artist, from the Isar cache
      final tracks = await _cache.getTracksByArtistId(targetId);

      // Could be sorted by play count once that is available;
      // for now it is the artist's songs.
      return right(tracks.map((t) => t.toEntity()).toList());
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, ArtistAlbums>> getAlbumsByArtistId(String id) async {
    try {
      final targetId = int.tryParse(id);
      if (targetId == null) {
        return left(const DatabaseFailure('Invalid ID format'));
      }

      final tracks = await _cache.getAlbumTracksByArtistId(targetId);
      return right(
        LibraryGrouping.albumsOfArtist(targetId, [
          for (final t in tracks) t.toEntity(),
        ]),
      );
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }
}
