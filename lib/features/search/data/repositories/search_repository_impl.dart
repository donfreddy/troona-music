import 'package:dartz/dartz.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/services/library_grouping.dart';
import 'package:troona/features/search/domain/entities/search_result.dart';
import 'package:troona/features/search/domain/repositories/search_repository.dart';

final class SearchRepositoryImpl implements SearchRepository {
  final IsarLibraryDataSource _db;

  SearchRepositoryImpl({required IsarLibraryDataSource db}) : _db = db {
    // Grouping the whole library is too slow for every keystroke: it is
    // done once, again after the songs change.
    _db.watchTracks().listen((_) => _grouped = null);
  }

  ({List<Artist> artists, List<Album> albums})? _grouped;

  Future<({List<Artist> artists, List<Album> albums})> _library() async {
    if (_grouped case final grouped?) return grouped;
    final tracks = [for (final t in await _db.getAllTracks()) t.toEntity()];
    return _grouped = (
      artists: LibraryGrouping.artistsOf(tracks, guests: true),
      albums: LibraryGrouping.albumsOf(tracks),
    );
  }

  @override
  Future<Either<Failure, SearchResult>> search(String query) async {
    if (query.trim().isEmpty) return right(SearchResult.empty());

    try {
      final tracks = [
        for (final t in await _db.searchTracks(query)) t.toEntity(),
      ];

      // Artists and albums as the library groups them, so a collaboration
      // finds each of its artists and a split album shows once.
      final library = await _library();
      final needle = query.trim().toLowerCase();
      bool matches(String name) => name.toLowerCase().contains(needle);
      final artists = [
        for (final a in library.artists)
          if (matches(a.name)) a,
      ];
      final albums = [
        for (final a in library.albums)
          if (matches(a.name)) a,
      ];

      return right(
        SearchResult(tracks: tracks, artists: artists, albums: albums),
      );
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }
}
