import 'package:dartz/dartz.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
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

      final tracks = (results[0]).map((t) => t.toEntity()).toList();

      // Deduplicate artists and enrich with counts and artwork
      final rawArtists = results[1];
      final seenArtists = <String>{};
      final uniqueArtistTracks = rawArtists.where((t) => seenArtists.add(t.artist)).toList();

      final artists = await Future.wait(
        uniqueArtistTracks.map((t) async {
          final artistTracks = await _db.getTracksByArtistId(t.artistId);
          final albumCount = artistTracks.map((x) => x.albumId).toSet().length;
          final artwork = t.artworkPath ??
              artistTracks
                  .where((x) => x.artworkPath != null && x.artworkPath!.isNotEmpty)
                  .firstOrNull
                  ?.artworkPath;
          return Artist(
            id: t.artistId.toString(),
            name: t.artist,
            artworkPath: artwork,
            trackCount: artistTracks.length,
            albumCount: albumCount,
          );
        }),
      );

      // Deduplicate albums and enrich with counts and artwork
      final rawAlbums = results[2];
      final seenAlbums = <String>{};
      final uniqueAlbumTracks = rawAlbums.where((t) => seenAlbums.add(t.album)).toList();

      final albums = await Future.wait(
        uniqueAlbumTracks.map((t) async {
          final albumTracks = await _db.getTracksByAlbumId(t.albumId);
          final artwork = t.artworkPath ??
              albumTracks
                  .where((x) => x.artworkPath != null && x.artworkPath!.isNotEmpty)
                  .firstOrNull
                  ?.artworkPath;
          return Album(
            id: t.albumId.toString(),
            name: t.album,
            artist: t.artist,
            artworkPath: artwork,
            artistId: t.artistId,
            trackCount: albumTracks.length,
          );
        }),
      );

      return right(
        SearchResult(tracks: tracks, artists: artists, albums: albums),
      );
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }
}
