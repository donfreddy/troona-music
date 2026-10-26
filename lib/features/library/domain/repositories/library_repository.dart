import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/services/scanner/media_scanner_service.dart';

abstract interface class LibraryRepository {
  /// Lance un scan de la librairie locale et renvoie la progression.
  Future<Either<Failure, Stream<ScanProgress>>> scanLibrary();

  /// Récupère tous les tracks indexés localement.
  Future<Either<Failure, List<Track>>> getTracks();

  /// Récupère les albums agrégés.
  Future<Either<Failure, List<Album>>> getAlbums();

  /// Récupère les artistes agrégés.
  Future<Either<Failure, List<Artist>>> getArtists();

  /// Recherche les tracks correspondant à [query].
  Future<Either<Failure, List<Track>>> searchTracks(String query);

  /// Playlist "Likes" (façon Spotify) — créée si absente.
  Future<Either<Failure, Playlist>> getLikesPlaylist();

  /// Ajoute un track à la playlist Likes (idempotent).
  Future<Either<Failure, Unit>> addTrackToLikes(String trackId);

  /// Retire un track de la playlist Likes.
  Future<Either<Failure, Unit>> removeTrackFromLikes(String trackId);

  /// Indique si le track est déjà dans Likes.
  Future<Either<Failure, bool>> isTrackInLikes(String trackId);
}
