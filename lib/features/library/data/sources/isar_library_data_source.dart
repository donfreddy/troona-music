import 'dart:io';

import 'package:isar_plus/isar_plus.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/data/models/playlist_model.dart';
import 'package:troona/features/library/data/models/track_model.dart';

/// Isar-backed persistent cache for the local music library.
///
/// Uses **isar_plus 4.x** conventions:
/// - All read operations are synchronous (Isar 4 runs queries on the caller
///   thread with no Future overhead).
/// - Write operations use [Isar.write], which wraps the callback in an atomic,
///   synchronous transaction that is committed on success and rolled back on
///   error.
/// - The async wrapper methods (returning [Future]) exist purely to satisfy the
///   interface contract used by higher layers and by the [MediaScannerService]
///   which runs on the main isolate.
///
/// **Lifecycle**: built on the shared database opened by `AppDatabase`, and
/// registered once as a singleton in the DI container.
///
/// **Code generation**: collection extension methods and schema objects are
/// generated from [TrackModel] and [PlaylistModel]. After any model change run:
/// ```sh
/// dart run build_runner build --delete-conflicting-outputs
/// ```
class IsarLibraryDataSource {
  final Isar _isar;

  IsarLibraryDataSource(this._isar);

  /// The collections this data source reads and writes.
  static final schemas = [TrackModelSchema, PlaylistModelSchema];

  // ---------------------------------------------------------------------------
  // Read operations  (synchronous Isar 4 queries, exposed as Future for callers)
  // ---------------------------------------------------------------------------

  /// Returns the set of [TrackModel.deviceId] values currently in the cache.
  ///
  /// Used by [MediaScannerService] to compute the diff between device and
  /// cache in O(n) where n is the number of cached tracks.
  ///
  /// TODO(perf): replace with a projection query once isar_plus exposes a
  /// `distinct` / `selectProperty` API to avoid loading full objects.
  Future<Set<String>> getAllDeviceIds() async {
    final tracks = _isar.trackModels.where().findAll();
    return tracks.map((t) => t.deviceId).toSet();
  }

  /// The device ids of the library's songs, the ones left out skipped.
  Future<Set<String>> getLibraryDeviceIds() async => _isar.trackModels
      .where()
      .not()
      .excludedEqualTo(true)
      .deviceIdProperty()
      .findAll()
      .toSet();

  /// Returns every [TrackModel] of the library, ordered by Isar insertion
  /// ID. Like every read here, it skips the songs the user's scan filter
  /// leaves out ([TrackModel.excluded]); [getStoredTracks] keeps them.
  Future<List<TrackModel>> getAllTracks() async =>
      _isar.trackModels.where().not().excludedEqualTo(true).findAll();

  /// Every stored row, the songs left out included: what a backup names, a
  /// restore matches and the folders page counts.
  Future<List<TrackModel>> getStoredTracks() async =>
      _isar.trackModels.where().findAll();

  /// Returns the number of tracks in the library.
  Future<int> countTracks() async =>
      _isar.trackModels.where().not().excludedEqualTo(true).count();

  /// Case-insensitive search across [TrackModel.title] and [TrackModel.artist].
  /// Artists and albums are searched among the ones the library groups.
  Future<List<TrackModel>> searchTracks(String query) async => _isar.trackModels
      .where()
      .not()
      .excludedEqualTo(true)
      .and()
      .group(
        (q) => q
            .titleContains(query, caseSensitive: false)
            .or()
            .artistContains(query, caseSensitive: false),
      )
      .findAll();

  /// Returns tracks the artwork extractor has not looked at yet; a song
  /// left out waits until it is let back in.
  Future<List<TrackModel>> getTracksWithoutArtwork() async => _isar.trackModels
      .where()
      .artworkCheckedEqualTo(false)
      .and()
      .not()
      .excludedEqualTo(true)
      .findAll();

  /// Returns the artwork path for a single track by [deviceId], or null.
  /// A cover the user picked comes first.
  Future<String?> getArtworkPathById(String deviceId) async {
    final track = _isar.trackModels
        .where()
        .deviceIdEqualTo(deviceId)
        .findFirst();
    return track?.editedCoverPath ?? track?.artworkPath;
  }

  /// Returns the playlists ordered by Isar insertion ID, with Likes ensured
  /// and pinned to the top.
  Future<List<PlaylistModel>> getPlaylists() async {
    await ensureLikes();
    final playlists = _isar.playlistModels.where().findAll();
    // Pin Likes playlist to index 0
    playlists.sort((a, b) {
      if (a.playlistId == likesPlaylistId) return -1;
      if (b.playlistId == likesPlaylistId) return 1;
      return 0;
    });
    return playlists;
  }

  /// Returns the playlist with [playlistId], or null if it does not exist.
  Future<PlaylistModel?> getPlaylistById(String playlistId) async {
    if (playlistId == likesPlaylistId) {
      return ensureLikes();
    }
    return _isar.playlistModels
        .where()
        .playlistIdEqualTo(playlistId)
        .findFirst();
  }

  /// Creates a new playlist; with [rulesJson], a smart one.
  Future<PlaylistModel> createPlaylist({
    required String title,
    String? description,
    String? artworkPath,
    String? rulesJson,
  }) async {
    final playlist = PlaylistModel()
      ..playlistId = DateTime.now().millisecondsSinceEpoch.toString()
      ..name = title
      // ..description = description
      ..artworkPath = artworkPath
      ..trackIds = []
      ..rulesJson = rulesJson;

    _isar.write((isar) {
      playlist.id = isar.playlistModels.autoIncrement();
      isar.playlistModels.put(playlist);
    });
    return playlist;
  }

  /// Updates an existing playlist.
  Future<void> updatePlaylist(PlaylistModel playlist) async {
    _isar.write((isar) {
      final existing = isar.playlistModels
          .where()
          .playlistIdEqualTo(playlist.playlistId)
          .findFirst();
      if (existing != null) {
        if (playlist.playlistId != likesPlaylistId) {
          existing.name = playlist.name;
        }
        existing.artworkPath = playlist.artworkPath;
        existing.trackIds = playlist.trackIds;
        if (playlist.playlistId != likesPlaylistId) {
          existing.rulesJson = playlist.rulesJson;
        }
        isar.playlistModels.put(existing);
      } else {
        if (playlist.id == 0) {
          playlist.id = isar.playlistModels.autoIncrement();
        }
        isar.playlistModels.put(playlist);
      }
    });
  }

  /// Deletes a playlist by its internal playlistId. Likes playlist cannot be deleted.
  Future<void> deletePlaylist(String playlistId) async {
    if (playlistId == likesPlaylistId) return;
    _isar.write((isar) {
      final playlist = isar.playlistModels
          .where()
          .playlistIdEqualTo(playlistId)
          .findFirst();
      if (playlist != null) {
        isar.playlistModels.delete(playlist.id);
      }
    });
  }

  /// Adds a track to a playlist.
  Future<void> addTrackToPlaylist(String playlistId, String trackId) async {
    _isar.write((isar) {
      final playlist = isar.playlistModels
          .where()
          .playlistIdEqualTo(playlistId)
          .findFirst();
      // A smart playlist's songs come from its rules: none are added.
      if (playlist != null &&
          playlist.rulesJson == null &&
          !playlist.trackIds.contains(trackId)) {
        playlist.trackIds.add(trackId);
        isar.playlistModels.put(playlist);
      }
    });
  }

  /// Adds [trackIds] to a playlist in one write, in their order, leaving
  /// out the ones it holds (and repeats). The ids added, in order; none
  /// when the playlist is gone.
  Future<List<String>> addTracksToPlaylist(
    String playlistId,
    List<String> trackIds,
  ) async {
    return _isar.write((isar) {
      final playlist = isar.playlistModels
          .where()
          .playlistIdEqualTo(playlistId)
          .findFirst();
      if (playlist == null || playlist.rulesJson != null) {
        return const <String>[];
      }
      final held = {...playlist.trackIds};
      final added = [
        for (final id in trackIds)
          if (held.add(id)) id,
      ];
      if (added.isEmpty) return added;
      playlist.trackIds = [...playlist.trackIds, ...added];
      isar.playlistModels.put(playlist);
      return added;
    });
  }

  /// Removes [trackIds] from a playlist in one write.
  Future<void> removeTracksFromPlaylist(
    String playlistId,
    List<String> trackIds,
  ) async {
    final gone = trackIds.toSet();
    _isar.write((isar) {
      final playlist = isar.playlistModels
          .where()
          .playlistIdEqualTo(playlistId)
          .findFirst();
      if (playlist == null) return;
      playlist.trackIds = [
        for (final id in playlist.trackIds)
          if (!gone.contains(id)) id,
      ];
      isar.playlistModels.put(playlist);
    });
  }

  /// Removes a track from a playlist.
  Future<void> removeTrackFromPlaylist(
    String playlistId,
    String trackId,
  ) async {
    _isar.write((isar) {
      final playlist = isar.playlistModels
          .where()
          .playlistIdEqualTo(playlistId)
          .findFirst();
      if (playlist != null) {
        playlist.trackIds.remove(trackId);
        isar.playlistModels.put(playlist);
      }
    });
  }

  /// Fires after every write to the playlists, the liked songs included.
  Stream<void> watchPlaylists() => _isar.playlistModels.watchLazy();

  /// Fires after every write to the tracks: a scan adding or removing
  /// songs, then saving their covers.
  Stream<void> watchTracks() => _isar.trackModels.watchLazy();

  /// Returns the list of tracks by their stable device IDs, preserving the
  /// exact order of [ids]. Returns an empty list if [ids] is empty.
  Future<List<TrackModel>> getTracksByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final tracks = _isar.trackModels
        .where()
        .anyOf(ids, (q, id) => q.deviceIdEqualTo(id))
        .findAll();
    final map = {
      for (final t in tracks)
        if (!t.excluded) t.deviceId: t,
    };
    return [
      for (final id in ids)
        if (map.containsKey(id)) map[id]!,
    ];
  }

  /// Returns the tracks that credit the artist [artistId], first or not.
  /// A row a scan has not linked yet has no credits: its own artist counts.
  Future<List<TrackModel>> getTracksByArtistId(int artistId) async => _isar
      .trackModels
      .where()
      .not()
      .excludedEqualTo(true)
      .and()
      .group(
        (q) =>
            q.artistIdsElementEqualTo(artistId).or().artistIdEqualTo(artistId),
      )
      .findAll();

  /// Returns every track of the albums in which the artist [artistId] is
  /// credited at least once.
  Future<List<TrackModel>> getAlbumTracksByArtistId(int artistId) async {
    final albumIds = {
      for (final t in await getTracksByArtistId(artistId)) t.albumId,
    };
    if (albumIds.isEmpty) return const [];
    return _isar.trackModels
        .where()
        .not()
        .excludedEqualTo(true)
        .and()
        .anyOf(albumIds, (q, id) => q.albumIdEqualTo(id))
        .sortByTrackNumber()
        .findAll();
  }

  /// Returns the list of tracks by album ID.
  Future<List<TrackModel>> getTracksByAlbumId(int albumId) async => _isar
      .trackModels
      .where()
      .albumIdEqualTo(albumId)
      .and()
      .not()
      .excludedEqualTo(true)
      .sortByTrackNumber()
      .findAll();

  // ── Likes playlist (Spotify-style) ─────────────────────────────────────────

  static const likesPlaylistId = Playlist.likesId;
  static const likesPlaylistName = 'Titres likés';

  /// Ensures the Likes playlist exists and returns it.
  Future<PlaylistModel> ensureLikes() async {
    final existing = _isar.playlistModels
        .where()
        .playlistIdEqualTo(likesPlaylistId)
        .findFirst();
    if (existing != null) {
      // Normalize name if it was previously 'Likes'
      if (existing.name != likesPlaylistName) {
        _isar.write((isar) {
          existing.name = likesPlaylistName;
          isar.playlistModels.put(existing);
        });
      }
      return existing;
    }

    final playlist = PlaylistModel()
      ..playlistId = likesPlaylistId
      ..name = likesPlaylistName
      ..artworkPath = null
      ..trackIds = [];

    _isar.write((isar) {
      if (playlist.id == 0) {
        playlist.id = isar.playlistModels.autoIncrement();
      }
      isar.playlistModels.put(playlist);
    });
    return playlist;
  }

  /// Adds [trackId] to the Likes playlist (idempotent, prepends newest first).
  Future<void> addTrackToLikes(String trackId) async => _isar.write((isar) {
    final playlist =
        isar.playlistModels
            .where()
            .playlistIdEqualTo(likesPlaylistId)
            .findFirst() ??
        (PlaylistModel()
          ..playlistId = likesPlaylistId
          ..name = likesPlaylistName
          ..artworkPath = null
          ..trackIds = []);

    if (!playlist.trackIds.contains(trackId)) {
      playlist.trackIds.insert(0, trackId);
      if (playlist.id == 0) {
        playlist.id = isar.playlistModels.autoIncrement();
      }
      isar.playlistModels.put(playlist);
    }
  });

  /// Removes [trackId] from Likes; no-op if absent.
  Future<void> removeTrackFromLikes(String trackId) async =>
      _isar.write((isar) {
        final playlist = isar.playlistModels
            .where()
            .playlistIdEqualTo(likesPlaylistId)
            .findFirst();
        if (playlist == null) return;
        playlist.trackIds.removeWhere((id) => id == trackId);
        isar.playlistModels.put(playlist);
      });

  Future<bool> isTrackInLikes(String trackId) async {
    final playlist = await getPlaylistById(likesPlaylistId);
    if (playlist == null) return false;
    return playlist.trackIds.contains(trackId);
  }

  /// Returns the set of all track IDs currently in the Likes playlist.
  Future<Set<String>> getLikedTrackIds() async {
    final playlist = await getPlaylistById(likesPlaylistId);
    return playlist?.trackIds.toSet() ?? const <String>{};
  }

  /// Returns up to [limit] most-recently-indexed tracks, sorted by
  /// [TrackModel.indexedAt] descending (newest first).
  Future<List<TrackModel>> getRecentTracks({int limit = 20}) async => _isar
      .trackModels
      .where()
      .not()
      .excludedEqualTo(true)
      .sortByIndexedAtDesc()
      .findAll(limit: limit);

  // ---------------------------------------------------------------------------
  // Write operations  (wrapped in Isar.write for atomicity)
  // ---------------------------------------------------------------------------

  /// Inserts [tracks] in a single atomic transaction.
  ///
  /// Only pass **new** tracks (those absent from [getAllDeviceIds]). The unique
  /// index on [TrackModel.deviceId] will reject duplicates.
  Future<void> insertTracks(List<TrackModel> tracks) async {
    _isar.write((isar) {
      for (final track in tracks) {
        if (track.id == 0) {
          track.id = isar.trackModels.autoIncrement();
        }
      }
      isar.trackModels.putAll(tracks);
    });
  }

  /// Removes all tracks whose [TrackModel.deviceId] is in [deviceIds].
  ///
  /// Resolves Isar integer IDs first, then performs a single bulk delete:
  /// all within one atomic transaction.
  Future<void> deleteByDeviceIds(List<String> deviceIds) async =>
      _isar.write((isar) {
        final isarIds = deviceIds
            .map(
              (id) =>
                  isar.trackModels.where().deviceIdEqualTo(id).findFirst()?.id,
            )
            .whereType<int>()
            .toList();
        isar.trackModels.deleteAll(isarIds);
      });

  /// Brings the indexed songs up to date with [scanned], the whole library
  /// as a scan read it and [TrackModel.link]ed: what their tags say now and
  /// the artists and albums they belong to (see [TrackModel.refreshFrom]).
  /// Only the rows that changed are written; covers are kept.
  Future<void> refreshIndexed(List<TrackModel> scanned) async {
    final byId = {for (final t in scanned) t.deviceId: t};
    final updated = [
      for (final row in _isar.trackModels.where().findAll())
        if (byId[row.deviceId] case final found?)
          if (row.refreshFrom(found)) row,
    ];
    if (updated.isEmpty) return;
    _isar.write((isar) => isar.trackModels.putAll(updated));
  }

  /// Records extraction results in one transaction: the cover path (null
  /// when the file has none) and the checked flag. Tracks deleted between
  /// scan phases are skipped.
  Future<void> saveArtworkResults(Map<String, String?> pathsByDeviceId) async {
    if (pathsByDeviceId.isEmpty) return;
    _isar.write((isar) {
      final updated = <TrackModel>[];
      for (final MapEntry(key: deviceId, value: path)
          in pathsByDeviceId.entries) {
        final track = isar.trackModels
            .where()
            .deviceIdEqualTo(deviceId)
            .findFirst();
        if (track == null) continue;
        track
          ..artworkPath = path
          ..artworkChecked = true;
        updated.add(track);
      }
      isar.trackModels.putAll(updated);
    });
  }

  /// Hands back to the extractor the songs whose cover file is gone: the
  /// covers live in the app's cache directory, which Android may empty
  /// (low storage, "Clear cache" in the system settings) while the rows
  /// still name them. Without this they would show no cover for good,
  /// marked as checked. Returns how many were reset.
  Future<int> forgetMissingArtwork() async {
    final rows = _isar.trackModels.where().artworkPathIsNotNull().findAll();
    // One listing per folder (they all share the cache's), not one check
    // per song: a library of thousands would queue thousands of them.
    final present = <String>{};
    // A folder that cannot be read says nothing of its files: its covers
    // are kept, and the scan goes on.
    final unread = <String>{};
    for (final folder in {
      for (final r in rows) File(r.artworkPath!).parent.path,
    }) {
      final dir = Directory(folder);
      try {
        if (!await dir.exists()) continue;
        await for (final entry in dir.list(followLinks: false)) {
          present.add(entry.path);
        }
      } on FileSystemException {
        unread.add(folder);
      }
    }
    final gone = {
      for (final row in rows)
        if (!present.contains(File(row.artworkPath!).path) &&
            !unread.contains(File(row.artworkPath!).parent.path))
          row.id: row.artworkPath,
    };
    if (gone.isEmpty) return 0;
    // Read again inside the write: a row changed during the checks keeps
    // its changes, and one given a new cover meanwhile keeps it.
    return _isar.write((isar) {
      final reset = [
        for (final row in isar.trackModels.getAll(gone.keys.toList()))
          if (row != null && row.artworkPath == gone[row.id])
            row
              ..artworkPath = null
              ..artworkChecked = false,
      ];
      isar.trackModels.putAll(reset);
      return reset.length;
    });
  }

  /// Clears the cached [artworkPath] for all tracks, so the next scan
  /// extracts them again.
  Future<void> clearAllArtworkPaths() async => _isar.write((isar) {
    final tracks = isar.trackModels.where().findAll();
    for (final t in tracks) {
      t
        ..artworkPath = null
        ..artworkChecked = false;
    }
    isar.trackModels.putAll(tracks);
  });
}
