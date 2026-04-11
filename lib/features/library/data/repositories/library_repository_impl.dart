import 'package:dartz/dartz.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/data/models/track_model.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/services/scanner/media_scanner_service.dart';

final class LibraryRepositoryImpl implements LibraryRepository {
  final IsarLibraryDataSource _cache;
  final MediaScannerService _scanner;

  const LibraryRepositoryImpl({
    required IsarLibraryDataSource cache,
    required MediaScannerService scanner,
  }) : _cache = cache,
       _scanner = scanner;

  @override
  Future<Either<Failure, Stream<ScanProgress>>> scanLibrary() async {
    try {
      return right(_scanner.scanLibrary());
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, List<Track>>> getTracks() async {
    try {
      final tracks = await _cache.getAllTracks();
      return right(tracks.map((t) => t.toEntity()).toList());
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, List<Album>>> getAlbums() async {
    try {
      //TODO: immolement this proprely later

      final tracks = await _cache.getAllTracks();

      final albumGroups = <String, List<TrackModel>>{};
      for (final t in tracks) {
        albumGroups.putIfAbsent(t.album, () => []).add(t);
      }

      final albums = albumGroups.values.map((group) {
        final firstTrack = group.first;
        return Album(
          id: firstTrack.albumId.toString(),
          name: firstTrack.album,
          artist: firstTrack.artist,
          artworkPath: firstTrack.artworkPath,
          artistId: firstTrack.artistId,
          trackCount: group.length,
        );
      }).toList();

      return right(albums);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, List<Artist>>> getArtists() async {
    try {
      final tracks = await _cache.getAllTracks();

      final artistGroups = <String, List<TrackModel>>{};
      for (final t in tracks) {
        artistGroups.putIfAbsent(t.artist, () => []).add(t);
      }

      final artists = artistGroups.values.map((group) {
        final firstTrack = group.first;
        final albumCount = group.map((t) => t.albumId).toSet().length;

        return Artist(
          id: firstTrack.artistId.toString(),
          name: firstTrack.artist,
          albumCount: albumCount,
          trackCount: group.length,
          artworkPath: firstTrack.artworkPath,
        );
      }).toList();

      return right(artists);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, List<Track>>> searchTracks(String query) async {
    try {
      final results = await _cache.searchTracks(query);
      return right(results.map((t) => t.toEntity()).toList());
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Playlist>> getLikesPlaylist() async {
    try {
      final playlist = await _cache.ensureLikes();
      return right(playlist.toEntity());
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> addTrackToLikes(String trackId) async {
    try {
      await _cache.addTrackToLikes(trackId);
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeTrackFromLikes(String trackId) async {
    try {
      await _cache.removeTrackFromLikes(trackId);
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, bool>> isTrackInLikes(String trackId) async {
    try {
      final liked = await _cache.isTrackInLikes(trackId);
      return right(liked);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }
}
