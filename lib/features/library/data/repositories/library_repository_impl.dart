import 'package:dartz/dartz.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/data/sources/local_audio_data_source.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/services/scanner/media_scanner_service.dart';

final class LibraryRepositoryImpl implements LibraryRepository {
  final LocalAudioDataSource _source;
  final IsarLibraryDataSource _cache;
  final MediaScannerService _scanner;

  const LibraryRepositoryImpl({
    required LocalAudioDataSource source,
    required IsarLibraryDataSource cache,
    required MediaScannerService scanner,
  })  : _source = source,
        _cache = cache,
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
      final albums = await _source.getAlbums();
      return right(albums.map((a) => a.toEntity()).toList());
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, List<Artist>>> getArtists() async {
    try {
      final artists = await _source.getArtists();
      return right(artists.map((a) => a.toEntity()).toList());
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
}
