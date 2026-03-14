import 'dart:typed_data';

import 'package:on_audio_query_pluse/on_audio_query.dart'
    hide AlbumModel, ArtistModel;
import 'package:troona/core/error/exceptions.dart';
import 'package:troona/features/library/data/models/album_model.dart';
import 'package:troona/features/library/data/models/artist_model.dart';
import 'package:troona/features/library/data/models/track_model.dart';

/// Contract for querying audio content from the device's media store.
abstract interface class LocalAudioDataSource {
  /// Scans all audio files available on the device.
  ///
  /// Returns a [Stream] so that results can be displayed progressively as
  /// chunks arrive, rather than waiting for the full scan to complete.
  Stream<List<TrackModel>> scanTracks();

  /// Fetches albums aggregated from the MediaStore.
  Future<List<AlbumModel>> getAlbums();

  /// Fetches artists from the MediaStore.
  Future<List<ArtistModel>> getArtists();

  /// Returns the artwork for [trackId] as raw JPEG bytes, or `null` when no
  /// artwork is available.
  Future<Uint8List?> getArtwork(int trackId);
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

/// [LocalAudioDataSource] backed by the `on_audio_query_pluse` package, which
/// queries the Android MediaStore (or the iOS media library).
final class OnAudioQueryDataSource implements LocalAudioDataSource {
  final OnAudioQuery _query;

  OnAudioQueryDataSource({OnAudioQuery? query})
    : _query = query ?? OnAudioQuery();

  @override
  Stream<List<TrackModel>> scanTracks() async* {
    // Request the audio permission before scanning.
    final hasPermission = await _query.permissionsStatus();
    if (!hasPermission) {
      final granted = await _query.permissionsRequest();
      if (!granted) {
        throw const PermissionException('Audio permission denied');
      }
    }

    // Fetch all audio files from external storage (SD card included).
    final songs = await _query.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    // Drop corrupted files and tracks shorter than 30 s (ringtones, SFX, …).
    final validSongs = songs.where(_isValidTrack).toList();

    // Emit in chunks of 50 so the UI can update progressively on large
    // libraries without blocking the UI thread.
    const chunkSize = 50;
    for (var i = 0; i < validSongs.length; i += chunkSize) {
      final chunk = validSongs.skip(i).take(chunkSize);
      yield chunk.map(TrackModel.fromSongModel).toList();

      // Brief yield point to avoid starving the UI isolate on large libraries.
      if (i + chunkSize < validSongs.length) {
        await Future.delayed(const Duration(milliseconds: 8));
      }
    }
  }

  @override
  Future<List<AlbumModel>> getAlbums() async {
    final albums = await _query.queryAlbums(
      sortType: AlbumSortType.ALBUM,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    return albums.map(AlbumModel.fromAlbumModel).toList();
  }

  @override
  Future<List<ArtistModel>> getArtists() async {
    final artists = await _query.queryArtists(
      sortType: ArtistSortType.ARTIST,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    return artists.map(ArtistModel.fromArtistModel).toList();
  }

  @override
  Future<Uint8List?> getArtwork(int trackId) async {
    return _query.queryArtwork(
      trackId,
      ArtworkType.AUDIO,
      format: ArtworkFormat.JPEG,
      size:
          500, // 500 px is sufficient for display and avoids OOM on low-end devices.
      quality: 85,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Returns `true` when [song] is a valid music track.
  ///
  /// Filters out:
  /// - Files shorter than 30 seconds (ringtones, sound effects).
  /// - Files with an empty title (likely corrupted).
  /// - Files with an empty path (no accessible storage location).
  bool _isValidTrack(SongModel song) {
    if ((song.duration ?? 0) < 30000) return false;
    if (song.title.isEmpty) return false;
    if (song.data.isEmpty) return false;
    return true;
  }
}
