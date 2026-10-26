import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/services/scanner/media_scanner_service.dart';

abstract interface class LibraryRepository {
  /// Starts a scan of the local library and streams its progress.
  Future<Either<Failure, Stream<ScanProgress>>> scanLibrary();

  /// Cancels the running scan.
  void cancelScan();

  /// Every locally indexed track.
  Future<Either<Failure, List<Track>>> getTracks();

  /// The tracks with these ids, in the same order; unknown ids are skipped.
  Future<Either<Failure, List<Track>>> getTracksByIds(List<String> ids);

  /// Albums aggregated from the tracks.
  Future<Either<Failure, List<Album>>> getAlbums();

  /// Artists aggregated from the tracks.
  Future<Either<Failure, List<Artist>>> getArtists();

  /// Tracks matching [query].
  Future<Either<Failure, List<Track>>> searchTracks(String query);

  /// The "Likes" playlist (Spotify style), created when missing.
  Future<Either<Failure, Playlist>> getLikesPlaylist();

  /// Adds a track to Likes (idempotent).
  Future<Either<Failure, Unit>> addTrackToLikes(String trackId);

  /// Removes a track from Likes.
  Future<Either<Failure, Unit>> removeTrackFromLikes(String trackId);

  /// Whether the track is already in Likes.
  Future<Either<Failure, bool>> isTrackInLikes(String trackId);
}
