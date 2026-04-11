import 'package:dartz/dartz.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/data/sources/local_audio_data_source.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/data/models/track_model.dart';
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

      final tracks = await _cache.getTracksByArtistId(targetId);

      if (tracks.isEmpty) {
        return left(const DatabaseFailure('Artist not found'));
      }

      final firstTrack = tracks.first;
      final albumCount = tracks.map((t) => t.albumId).toSet().length;

      return right(Artist(
        id: firstTrack.artistId.toString(),
        name: firstTrack.artist,
        albumCount: albumCount,
        trackCount: tracks.length,
        artworkPath: firstTrack.artworkPath,
      ));
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

      final tracks = await _cache.getTracksByArtistId(targetId);
      
      // Group by album name to reliably count tracks and grab the first artwork
      final albumGroups = <String, List<TrackModel>>{};
      for (final t in tracks) {
        albumGroups.putIfAbsent(t.album, () => []).add(t);
      }

      final artistAlbums = albumGroups.values.map((group) {
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

      return right(artistAlbums);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }
}
