import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/smart_rules.dart';
import 'package:troona/features/library/domain/entities/track.dart';

abstract interface class PlaylistRepository {
  // Lecture
  Future<Either<Failure, List<Playlist>>> getPlaylists();
  Future<Either<Failure, Playlist>> getPlaylistById(String id);
  Future<Either<Failure, List<Track>>> getTracksByPlaylistId(String id);

  /// Fires after any change to the stored playlists, whoever made it.
  Stream<void> watchPlaylists();

  // Writes (CRUD)
  /// With [rules], a smart playlist: its songs come from them, and it
  /// takes no song added, removed or moved.
  Future<Either<Failure, Playlist>> createPlaylist({
    required String title,
    String? description,
    String? artworkPath,
    SmartRules? rules,
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

  /// Adds [trackIds] in one write, all or none, in their order, leaving out
  /// the ones the playlist holds. The ids added.
  Future<Either<Failure, List<String>>> addTracksToPlaylist(
    String playlistId,
    List<String> trackIds,
  );

  /// Removes [trackIds] in one write (an Undo of [addTracksToPlaylist]).
  Future<Either<Failure, Unit>> removeTracksFromPlaylist(
    String playlistId,
    List<String> trackIds,
  );
  Future<Either<Failure, Unit>> reorderTracks(
    String playlistId,
    int oldIndex,
    int newIndex,
  );
}
