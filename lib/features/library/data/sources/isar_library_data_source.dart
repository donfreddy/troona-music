import 'package:troona/features/library/data/models/playlist_model.dart';
import 'package:troona/features/library/data/models/track_model.dart';

/// Simplified in-memory implementation used until the Isar-backed
/// persistence layer is wired. Keeps the rest of the app working and
/// prevents null/dynamic errors during scanning.
class IsarLibraryDataSource {
  final Map<String, TrackModel> _tracks = {};
  final List<PlaylistModel> _playlists = [];

  /// Returns the set of all device IDs currently cached.
  Future<Set<String>> getAllDeviceIds() async => _tracks.keys.toSet();

  /// Returns every cached track.
  Future<List<TrackModel>> getAllTracks() async => _tracks.values.toList();

  /// Case-insensitive search across title and artist.
  Future<List<TrackModel>> searchTracks(String query) async {
    final lower = query.toLowerCase();
    return _tracks.values
        .where((t) => t.title.toLowerCase().contains(lower) || t.artist.toLowerCase().contains(lower))
        .toList();
  }

  /// Inserts or replaces tracks by deviceId.
  Future<void> insertTracks(List<TrackModel> tracks) async {
    for (final track in tracks) {
      _tracks[track.deviceId] = track;
    }
  }

  /// Deletes tracks whose deviceIds are provided.
  Future<void> deleteByDeviceIds(List<String> deviceIds) async {
    for (final id in deviceIds) {
      _tracks.remove(id);
    }
  }

  /// Returns tracks that have no cached artwork yet.
  Future<List<TrackModel>> getTracksWithoutArtwork() async => _tracks.values
      .where((t) => t.artworkPath == null || t.artworkPath!.isEmpty)
      .toList();

  /// Updates the cached artwork path for a track.
  Future<void> updateArtworkPath(String deviceId, String artworkPath) async {
    final track = _tracks[deviceId];
    if (track != null) {
      track.artworkPath = artworkPath;
    }
  }

  /// Placeholder: returns popular playlists (empty until real storage is added).
  Future<List<PlaylistModel>> getPlaylists({int limit = 10}) async =>
      _playlists.take(limit).toList();

  /// Placeholder: returns recent tracks (currently insertion order).
  Future<List<TrackModel>> getRecentTracks({int limit = 20}) async =>
      _tracks.values.take(limit).toList();
}
