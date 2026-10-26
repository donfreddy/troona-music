import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/track.dart';

abstract interface class PlaylistRepository {
  // Lecture
  Future<Either<Failure, List<Playlist>>> getPlaylists();
  Future<Either<Failure, Playlist>> getPlaylistById(String id);
  Future<Either<Failure, List<Track>>> getTracksByPlaylistId(String id);

  // Writes (CRUD)
  Future<Either<Failure, Playlist>> createPlaylist({
    required String title,
    String? description,
    String? artworkPath,
  });

  Future<Either<Failure, Unit>> updatePlaylist(Playlist playlist);
  Future<Either<Failure, Unit>> deletePlaylist(String id);

  // Songs
  Future<Either<Failure, Unit>> addTrackToPlaylist(
    String playlistId,
    String trackId,
  );
  Future<Either<Failure, Unit>> removeTrackFromPlaylist(
    String playlistId,
    String trackId,
  );
  Future<Either<Failure, Unit>> reorderTracks(
    String playlistId,
    int oldIndex,
    int newIndex,
  );
}
