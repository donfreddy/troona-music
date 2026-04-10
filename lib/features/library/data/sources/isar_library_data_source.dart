import 'package:isar_plus/isar_plus.dart';
import 'package:path_provider/path_provider.dart';
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
/// **Lifecycle**: call [IsarLibraryDataSource.open] once during app
/// initialisation and register the returned instance as a singleton in your DI
/// container. Call [close] when the app terminates (optional on mobile — the
/// OS reclaims resources on process exit).
///
/// **Code generation**: collection extension methods and schema objects are
/// generated from [TrackModel] and [PlaylistModel]. After any model change run:
/// ```sh
/// dart run build_runner build --delete-conflicting-outputs
/// ```
class IsarLibraryDataSource {
  final Isar _isar;

  IsarLibraryDataSource._(this._isar);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Opens (or re-uses) the Isar database in the app's documents directory.
  ///
  /// Safe to call multiple times — Isar returns the existing instance when the
  /// same [name] is already open in the current isolate.
  static Future<IsarLibraryDataSource> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.openAsync(
      schemas: [TrackModelSchema, PlaylistModelSchema],
      directory: dir.path,
      name: 'troona',
    );
    return IsarLibraryDataSource._(isar);
  }

  /// Releases the Isar instance.
  ///
  /// Returns `true` if this was the last reference and the database was closed.
  bool close() => _isar.close();

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

  /// Returns every cached [TrackModel], ordered by Isar insertion ID.
  Future<List<TrackModel>> getAllTracks() async =>
      _isar.trackModels.where().findAll();

  /// Returns the total number of tracks in the cache.
  Future<int> countTracks() async => _isar.trackModels.count();

  /// Case-insensitive search across [TrackModel.title] and [TrackModel.artist].
  Future<List<TrackModel>> searchTracks(String query) async => _isar.trackModels
      .where()
      .titleContains(query, caseSensitive: false)
      .or()
      .artistContains(query, caseSensitive: false)
      .findAll();

  /// Case-insensitive search for artists.
  Future<List<TrackModel>> searchArtists(String query) async {
    final tracks = _isar.trackModels
        .where()
        .artistContains(query, caseSensitive: false)
        .findAll();

    final seen = <String>{};
    return tracks.where((t) => seen.add(t.artist)).toList();
  }

  /// Case-insensitive search for albums.
  Future<List<TrackModel>> searchAlbums(String query) async {
    final tracks = _isar.trackModels
        .where()
        .albumContains(query, caseSensitive: false)
        .findAll();

    final seen = <String>{};
    return tracks.where((t) => t.album != null && seen.add(t.album!)).toList();
  }

  /// Returns tracks that have no artwork cached yet (null or empty path).
  Future<List<TrackModel>> getTracksWithoutArtwork() async => _isar.trackModels
      .where()
      .artworkPathIsNull()
      .or()
      .artworkPathEqualTo('')
      .findAll();

  /// Returns the artwork path for a single track by [deviceId], or null.
  Future<String?> getArtworkPathById(String deviceId) async => _isar.trackModels
      .where()
      .deviceIdEqualTo(deviceId)
      .findFirst()
      ?.artworkPath;

  /// Returns up to [limit] playlists ordered by Isar insertion ID.
  Future<List<PlaylistModel>> getPlaylists({int limit = 50}) async =>
      _isar.playlistModels.where().findAll(limit: limit);

  /// Returns the playlist with [playlistId], or null if it does not exist.
  Future<PlaylistModel?> getPlaylistById(String playlistId) async =>
      _isar.playlistModels.where().playlistIdEqualTo(playlistId).findFirst();

  /// Creates a new playlist.
  Future<PlaylistModel> createPlaylist({
    required String title,
    String? description,
    String? artworkPath,
  }) async {
    final playlist = PlaylistModel()
      ..playlistId = DateTime.now().millisecondsSinceEpoch.toString()
      ..name = title
     // ..description = description
      ..artworkPath = artworkPath
      ..trackIds = [];

    _isar.write((isar) {
      playlist.id = isar.playlistModels.autoIncrement();
      isar.playlistModels.put(playlist);
    });
    return playlist;
  }

  /// Updates an existing playlist.
  Future<void> updatePlaylist(PlaylistModel playlist) async {
    _isar.write((isar) {
      isar.playlistModels.put(playlist);
    });
  }

  /// Deletes a playlist by its internal playlistId.
  Future<void> deletePlaylist(String playlistId) async {
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
      if (playlist != null && !playlist.trackIds.contains(trackId)) {
        playlist.trackIds.add(trackId);
        isar.playlistModels.put(playlist);
      }
    });
  }

  /// Removes a track from a playlist.
  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {
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

  /// Returns the list of tracks by their stable device IDs.
  Future<List<TrackModel>> getTracksByIds(List<String> ids) async => _isar
      .trackModels
      .where()
      .anyOf(ids, (q, id) => q.deviceIdEqualTo(id))
      .findAll();

  /// Returns the list of tracks by artist ID.
  Future<List<TrackModel>> getTracksByArtistId(int artistId) async => _isar
      .trackModels
      .where()
      .artistIdEqualTo(artistId)
      .findAll();

  /// Returns the list of tracks by album ID.
  Future<List<TrackModel>> getTracksByAlbumId(int albumId) async => _isar
      .trackModels
      .where()
      .albumIdEqualTo(albumId)
      .findAll();

  // ── Likes playlist (Spotify-style) ─────────────────────────────────────────

  static const likesPlaylistId = 'likes';
  static const likesPlaylistName = 'Likes';

  /// Ensures the Likes playlist exists and returns it.
  Future<PlaylistModel> ensureLikes() async {
    final existing = await getPlaylistById(likesPlaylistId);
    if (existing != null) return existing;

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

  /// Returns up to [limit] most-recently-indexed tracks, sorted by
  /// [TrackModel.indexedAt] descending (newest first).
  Future<List<TrackModel>> getRecentTracks({int limit = 20}) async =>
      _isar.trackModels.where().sortByIndexedAtDesc().findAll(limit: limit);

  /// Returns a list of tracks grouped by artist.
  Future<List<TrackModel>> getUniqueArtists({int limit = 5}) async {
    final tracks = _isar.trackModels.where().findAll();
    final seenArtists = <String>{};
    final uniqueTracks = <TrackModel>[];

    for (final track in tracks) {
      if (!seenArtists.contains(track.artist)) {
        seenArtists.add(track.artist);
        uniqueTracks.add(track);
        if (uniqueTracks.length >= limit) break;
      }
    }
    return uniqueTracks;
  }

  /// Returns a list of tracks grouped by album.
  Future<List<TrackModel>> getUniqueAlbums({int limit = 5}) async {
    final tracks = _isar.trackModels.where().sortByIndexedAtDesc().findAll();
    final seenAlbums = <String>{};
    final uniqueTracks = <TrackModel>[];

    for (final track in tracks) {
      if (track.album != null && !seenAlbums.contains(track.album)) {
        seenAlbums.add(track.album!);
        uniqueTracks.add(track);
        if (uniqueTracks.length >= limit) break;
      }
    }
    return uniqueTracks;
  }

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
  /// Resolves Isar integer IDs first, then performs a single bulk delete —
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

  /// Updates the cached [artworkPath] for the track identified by [deviceId].
  ///
  /// Silently no-ops when the track is not found (e.g. deleted between scan
  /// phases).
  Future<void> updateArtworkPath(String deviceId, String artworkPath) async =>
      _isar.write((isar) {
        final track = isar.trackModels
            .where()
            .deviceIdEqualTo(deviceId)
            .findFirst();
        if (track == null) return;
        track.artworkPath = artworkPath;
        isar.trackModels.put(track);
      });
}
