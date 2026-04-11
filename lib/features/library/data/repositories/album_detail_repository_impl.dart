import 'package:dartz/dartz.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/data/sources/local_audio_data_source.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/album_detail_repository.dart';

final class AlbumDetailRepositoryImpl implements AlbumDetailRepository {
  final LocalAudioDataSource _source;
  final IsarLibraryDataSource _cache;

  const AlbumDetailRepositoryImpl({required LocalAudioDataSource source, required IsarLibraryDataSource cache})
    : _source = source,
      _cache = cache;

  @override
  Future<Either<Failure, Album>> getAlbumById(String id) async {
    try {
      final targetId = int.tryParse(id);
      if (targetId == null) {
        return left(const DatabaseFailure('Invalid album ID format'));
      }

      final albums = await _source.getAlbums();
      final album = albums.where((a) => a.id == targetId).firstOrNull;
      final tracks = await _cache.getTracksByAlbumId(targetId);

      if (album == null) {
        return left(const DatabaseFailure('Album not found'));
      }

      return right(album.toEntity().copyWith(artworkPath: tracks[0].artworkPath));
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, List<Album>>> getAlbumsByArtistId(int artistId) async {
    try {
      final albums = await _source.getAlbums();
      final artistAlbums = albums.where((a) => a.artistId == artistId).map((a) => a.toEntity()).toList();

      final resultAlbums = <Album>[];
      for (final a in artistAlbums) {
        final albumId = int.tryParse(a.id);
        if (albumId != null) {
          final tracks = await _cache.getTracksByAlbumId(albumId);
          resultAlbums.add(a.copyWith(artworkPath: tracks.firstOrNull?.artworkPath));
        } else {
          resultAlbums.add(a);
        }
      }

      return right(resultAlbums);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  // @override
  // Future<Either<Failure, List<Track>>> getTracksByArtistId(int id) async {
  //   try {
  //     final tracks = await _cache.getTracksByArtistId(id);
  //     return right(tracks.map((t) => t.toEntity()).toList());
  //   } catch (e, st) {
  //     return left(ErrorHandler.handle(e, st));
  //   }
  // }

  @override
  Future<Either<Failure, List<Track>>> getTracksByAlbumId(int id) async {
    try {
      final tracks = await _cache.getTracksByAlbumId(id);
      return right(tracks.map((t) => t.toEntity()).toList());
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }
}
