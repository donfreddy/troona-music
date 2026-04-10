import 'package:dartz/dartz.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/data/models/track_model.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/search/domain/entities/search_result.dart';
import 'package:troona/features/search/domain/repositories/search_repository.dart';

final class SearchRepositoryImpl implements SearchRepository {
  final IsarLibraryDataSource _db;

  const SearchRepositoryImpl({required IsarLibraryDataSource db}) : _db = db;

  @override
  Future<Either<Failure, SearchResult>> search(String query) async {
    if (query.trim().isEmpty) return right(SearchResult.empty());

    try {
      final results = await Future.wait([
        _db.searchTracks(query),
        _db.searchArtists(query),
        _db.searchAlbums(query),
      ]);

      final tracks = (results[0] as List<TrackModel>).map((t) => t.toEntity()).toList();

      final artists = (results[1] as List<TrackModel>).map((t) => Artist(
        id: t.artistId ?? 0,
        name: t.artist,
        artworkPath: t.artworkPath,
        trackCount: 0,
      )).toList();

      final albums = (results[2] as List<TrackModel>).map((t) => Album(
        id: t.albumId ?? 0,
        title: t.album ?? 'Unknown Album',
        artist: t.artist,
        artworkPath: t.artworkPath,
        year: null,
      )).toList();

      return right(SearchResult(
        tracks: tracks,
        artists: artists,
        albums: albums,
      ));
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }
}
