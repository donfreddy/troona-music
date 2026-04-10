import 'package:dartz/dartz.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/data/models/playlist_model.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/playlist/domain/repositories/playlist_repository.dart';

final class PlaylistRepositoryImpl implements PlaylistRepository {
  final IsarLibraryDataSource _cache;

  const PlaylistRepositoryImpl({
    required IsarLibraryDataSource cache,
  }) : _cache = cache;

  @override
  Future<Either<Failure, List<Playlist>>> getPlaylists() async {
    try {
      final playlists = await _cache.getPlaylists();
      return right(playlists.map((p) => p.toEntity()).toList());
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Playlist>> getPlaylistById(String id) async {
    try {
      final playlist = await _cache.getPlaylistById(id);
      if (playlist == null) return left(const DatabaseFailure('Playlist not found'));
      return right(playlist.toEntity());
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, List<Track>>> getTracksByPlaylistId(String id) async {
    try {
      final playlist = await _cache.getPlaylistById(id);
      if (playlist == null) return left(const DatabaseFailure('Playlist not found'));
      
      final tracks = await _cache.getTracksByIds(playlist.trackIds);
      return right(tracks.map((t) => t.toEntity()).toList());
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Playlist>> createPlaylist({
    required String title,
    String? description,
    String? artworkPath,
  }) async {
    try {
      final playlist = await _cache.createPlaylist(
        title: title,
        description: description,
        artworkPath: artworkPath,
      );
      return right(playlist.toEntity());
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePlaylist(Playlist playlist) async {
    try {
      final model = PlaylistModel()
        ..id = playlist.id
        ..playlistId = playlist.playlistId
        ..name = playlist.name
        ..description = playlist.description
        ..artworkPath = playlist.artworkPath
        ..trackIds = playlist.trackIds;
      
      await _cache.updatePlaylist(model);
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePlaylist(String id) async {
    try {
      await _cache.deletePlaylist(id);
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> addTrackToPlaylist(String playlistId, int trackId) async {
    try {
      await _cache.addTrackToPlaylist(playlistId, trackId.toString());
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeTrackFromPlaylist(String playlistId, int trackId) async {
    try {
      await _cache.removeTrackFromPlaylist(playlistId, trackId.toString());
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> reorderTracks(String playlistId, int oldIndex, int newIndex) async {
    try {
      final playlist = await _cache.getPlaylistById(playlistId);
      if (playlist == null) return left(const DatabaseFailure('Playlist not found'));

      final tracks = List<String>.from(playlist.trackIds);
      final item = tracks.removeAt(oldIndex);
      tracks.insert(newIndex, item);
      
      playlist.trackIds = tracks;
      await _cache.updatePlaylist(playlist);
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }
}
