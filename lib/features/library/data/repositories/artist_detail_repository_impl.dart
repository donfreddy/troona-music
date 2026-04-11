import 'package:dartz/dartz.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/data/sources/local_audio_data_source.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/artist_detail_repository.dart';

final class ArtistDetailRepositoryImpl implements ArtistDetailRepository {
  final LocalAudioDataSource _source;
  final IsarLibraryDataSource _cache;

  const ArtistDetailRepositoryImpl({
    required LocalAudioDataSource source,
    required IsarLibraryDataSource cache,
  }) : _source = source,
       _cache = cache;

  @override
  Future<Either<Failure, Artist>> getArtistById(String id) async {
    try {
      final targetId = int.tryParse(id);
      if (targetId == null) {
        return left(const DatabaseFailure('Invalid artist ID format'));
      }

      final artists = await _source.getArtists();
      final artist = artists.where((a) => a.id == targetId).firstOrNull;

      if (artist == null) {
        return left(const DatabaseFailure('Artist not found'));
      }

      return right(artist.toEntity());
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

      // On récupère tous les morceaux de cet artiste depuis le cache Isar
      final tracks = await _cache.getTracksByArtistId(targetId);

      // Ici tu pourrais trier par nombre d'écoutes si tu avais l'info,
      // pour l'instant on prend les morceaux de l'artiste.
      return right(tracks.map((t) => t.toEntity()).toList());
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, List<Album>>> getAlbumsByArtistId(String id) async {
    try {
      final targetId = int.tryParse(id);
      if (targetId == null) {
        return left(const DatabaseFailure('Invalid ID format'));
      }

      final albums = await _source.getAlbums();
      final artistAlbums = albums
          .where((a) => a.artistId == targetId)
          .map((a) => a.toEntity())
          .toList();

      return right(artistAlbums);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }
}
