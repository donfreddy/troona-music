import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/track.dart';

abstract interface class PlaylistRepository {
  // Lecture
  Future<Either<Failure, List<Playlist>>> getPlaylists();
  Future<Either<Failure, Playlist>> getPlaylistById(String id);
  Future<Either<Failure, List<Track>>> getTracksByPlaylistId(String id);

  // Écriture (CRUD)
  Future<Either<Failure, Playlist>> createPlaylist({
    required String title,
    String? description,
    String? artworkPath,
  });

  Future<Either<Failure, Unit>> updatePlaylist(Playlist playlist);
  Future<Either<Failure, Unit>> deletePlaylist(String id);

  // Gestion des morceaux
  Future<Either<Failure, Unit>> addTrackToPlaylist(String playlistId, int trackId);
  Future<Either<Failure, Unit>> removeTrackFromPlaylist(String playlistId, int trackId);
  Future<Either<Failure, Unit>> reorderTracks(String playlistId, int oldIndex, int newIndex);
}
