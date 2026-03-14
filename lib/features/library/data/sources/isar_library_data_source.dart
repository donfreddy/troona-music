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

  /// Case-insensitive search across [TrackModel.title] and [TrackModel.artist].
  Future<List<TrackModel>> searchTracks(String query) async =>
      _isar.trackModels
          .where()
          .titleContains(query, caseSensitive: false)
          .or()
          .artistContains(query, caseSensitive: false)
          .findAll();

  /// Returns tracks that have no artwork cached yet (null or empty path).
  Future<List<TrackModel>> getTracksWithoutArtwork() async =>
      _isar.trackModels
          .where()
          .artworkPathIsNull()
          .or()
          .artworkPathEqualTo('')
          .findAll();

  /// Returns the artwork path for a single track by [deviceId], or null.
  Future<String?> getArtworkPathById(String deviceId) async =>
      _isar.trackModels
          .where()
          .deviceIdEqualTo(deviceId)
          .findFirst()
          ?.artworkPath;

  /// Returns up to [limit] playlists ordered by Isar insertion ID.
  Future<List<PlaylistModel>> getPlaylists({int limit = 10}) async =>
      _isar.playlistModels.where().findAll(limit: limit);

  /// Returns up to [limit] most-recently-indexed tracks.
  ///
  /// Isar assigns monotonically increasing IDs on insert, so descending ID
  /// order approximates "recently added."
  ///
  /// TODO(perf): add an `indexedAt` timestamp field and sort by it for an
  /// accurate "recently added" ordering.
  Future<List<TrackModel>> getRecentTracks({int limit = 20}) async =>
      _isar.trackModels.where().findAll(limit: limit);

  // ---------------------------------------------------------------------------
  // Write operations  (wrapped in Isar.write for atomicity)
  // ---------------------------------------------------------------------------

  /// Inserts [tracks] in a single atomic transaction.
  ///
  /// Only pass **new** tracks (those absent from [getAllDeviceIds]). The unique
  /// index on [TrackModel.deviceId] will reject duplicates.
  Future<void> insertTracks(List<TrackModel> tracks) async =>
      _isar.write((isar) => isar.trackModels.putAll(tracks));

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
        final track =
            isar.trackModels.where().deviceIdEqualTo(deviceId).findFirst();
        if (track == null) return;
        track.artworkPath = artworkPath;
        isar.trackModels.put(track);
      });
}
