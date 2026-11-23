import 'package:dartz/dartz.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/data/models/smart_rules_json.dart';
import 'package:troona/features/library/domain/entities/smart_rules.dart';
import 'package:troona/features/library/data/models/playlist_model.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:troona/features/playlist/domain/services/playlist_order.dart';

final class PlaylistRepositoryImpl implements PlaylistRepository {
  final IsarLibraryDataSource _cache;

  const PlaylistRepositoryImpl({required IsarLibraryDataSource cache})
    : _cache = cache;

  @override
  Future<Either<Failure, List<Playlist>>> getPlaylists() async {
    try {
      final playlists = await _cache.getPlaylists();
      final library = await _cache.getLibraryDeviceIds();
      return right([for (final p in playlists) p.toEntity(library: library)]);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Playlist>> getPlaylistById(String id) async {
    try {
      final playlist = await _cache.getPlaylistById(id);
      if (playlist == null) {
        return left(const DatabaseFailure('Playlist not found'));
      }
      return right(
        playlist.toEntity(library: await _cache.getLibraryDeviceIds()),
      );
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, List<Track>>> getTracksByPlaylistId(String id) async {
    try {
      final playlist = await _cache.getPlaylistById(id);
      if (playlist == null) {
        return left(const DatabaseFailure('Playlist not found'));
      }

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
    SmartRules? rules,
  }) async {
    try {
      final playlist = await _cache.createPlaylist(
        title: title,
        description: description,
        artworkPath: artworkPath,
        rulesJson: rules == null ? null : SmartRulesJson.encodeString(rules),
      );
      return right(playlist.toEntity());
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePlaylist(Playlist playlist) async {
    if (playlist.id == IsarLibraryDataSource.likesPlaylistId) {
      return left(
        const DatabaseFailure('Impossible de modifier la playlist des favoris'),
      );
    }
    try {
      final model = PlaylistModel()
        ..playlistId = playlist.id
        ..name = playlist.name
        ..artworkPath = playlist.artworkPath
        ..trackIds = playlist.trackIds
        ..rulesJson = switch (playlist.rules) {
          final rules? => SmartRulesJson.encodeString(rules),
          null => null,
        };

      await _cache.updatePlaylist(model);
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePlaylist(String id) async {
    if (id == IsarLibraryDataSource.likesPlaylistId) {
      return left(
        const DatabaseFailure('The liked songs playlist cannot be deleted'),
      );
    }
    try {
      await _cache.deletePlaylist(id);
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> addTrackToPlaylist(
    String playlistId,
    String trackId,
  ) async {
    try {
      await _cache.addTrackToPlaylist(playlistId, trackId);
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeTrackFromPlaylist(
    String playlistId,
    String trackId,
  ) async {
    try {
      await _cache.removeTrackFromPlaylist(playlistId, trackId);
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, List<String>>> addTracksToPlaylist(
    String playlistId,
    List<String> trackIds,
  ) async {
    try {
      return right(await _cache.addTracksToPlaylist(playlistId, trackIds));
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeTracksFromPlaylist(
    String playlistId,
    List<String> trackIds,
  ) async {
    try {
      await _cache.removeTracksFromPlaylist(playlistId, trackIds);
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> reorderTracks(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      final playlist = await _cache.getPlaylistById(playlistId);
      if (playlist == null) {
        return left(const DatabaseFailure('Playlist not found'));
      }
      if (playlist.rulesJson != null) {
        return left(const DatabaseFailure('A smart playlist has no order'));
      }

      // The page numbers only the songs it shows.
      final shown = {
        for (final t in await _cache.getTracksByIds(playlist.trackIds))
          t.deviceId,
      };
      final tracks = PlaylistOrder.move(
        playlist.trackIds,
        shown.contains,
        from: oldIndex,
        to: newIndex,
      );
      if (tracks == null) {
        return left(const DatabaseFailure('No song at that place'));
      }

      playlist.trackIds = tracks;
      await _cache.updatePlaylist(playlist);
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Stream<void> watchPlaylists() => _cache.watchPlaylists();
}
