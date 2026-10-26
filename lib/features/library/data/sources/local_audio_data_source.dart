import 'package:flutter/foundation.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart'
    hide AlbumModel, ArtistModel;
import 'package:troona/core/error/exceptions.dart';
import 'package:troona/core/utils/permission_handler.dart';
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

  /// Low on purpose: album intros, skits and interludes are often 20 to
  /// 40 s. System sounds are excluded by the MediaStore flags instead.
  static const _minTrackDurationMs = 10 * 1000;
  static const _allowedExtensions = {
    'mp3',
    'm4a',
    'aac',
    'flac',
    'wav',
    'ogg',
    'opus',
  };
  static const _blockedPathFragments = {
    '/alarms/',
    '/notifications/',
    '/ringtones/',
    '/ui/',
    '/system/',
    '/system/media/audio/',
    '/recordings/call/',
    '/whatsapp voice notes/',
    '/telegram/audio/',
    '/telegram voice/',
  };

  OnAudioQueryDataSource({OnAudioQuery? query})
    : _query = query ?? OnAudioQuery();

  @override
  Stream<List<TrackModel>> scanTracks() async* {
    // Permission flow is centralized in AppPermissionHandler / router guard.
    // Rely on its platform-aware check only: the plugin's own
    // permissionsStatus() uses READ_EXTERNAL_STORAGE internally, which is
    // deprecated and always returns false on API 33+.
    final hasPermission = await AppPermissionHandler.hasAudioPermission();
    if (!hasPermission) {
      throw const PermissionException('Audio permission denied');
    }

    // Fetch all audio files from external storage (SD card included).
    final songs = await _query.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    // Filter valid tracks safely item-by-item so a single malformed model
    // doesn't fail the whole scan.
    final validTracks = <TrackModel>[];
    for (final song in songs) {
      try {
        if (_isValidTrack(song)) {
          validTracks.add(TrackModel.fromSongModel(song));
        }
      } catch (_) {
        // Skip malformed track
      }
    }

    // Emit in chunks of 50 so the UI can update progressively on large
    // libraries without blocking the UI thread.
    const chunkSize = 50;
    for (var i = 0; i < validTracks.length; i += chunkSize) {
      final chunk = validTracks.skip(i).take(chunkSize).toList();
      yield chunk;

      // Brief yield point to avoid starving the UI isolate on large libraries.
      if (i + chunkSize < validTracks.length) {
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
  /// - Non-music items reported by MediaStore.
  /// - Files shorter than 10 seconds, and empty files.
  /// - System / messaging app audio directories.
  /// - Files with an empty title (likely corrupted).
  /// - Files with an empty path (no accessible storage location).
  bool _isValidTrack(SongModel song) {
    final path = song.data.trim();
    final title = song.title.trim();
    final lowerPath = path.toLowerCase();
    final extension = song.fileExtension.toLowerCase();

    if (title.isEmpty) return false;
    if (path.isEmpty) return false;
    if (song.isMusic == false) return false;
    if (song.isAlarm == true ||
        song.isNotification == true ||
        song.isRingtone == true ||
        song.isPodcast == true ||
        song.isAudioBook == true) {
      return false;
    }
    if ((song.duration ?? 0) < _minTrackDurationMs) return false;
    if (song.size <= 0) return false;
    if (!_allowedExtensions.contains(extension)) return false;
    if (lowerPath.contains(
      '/android/media/com.whatsapp/business/voice notes/',
    )) {
      return false;
    }
    if (_blockedPathFragments.any(lowerPath.contains)) return false;
    if (title.toLowerCase() == 'audio') return false;

    return true;
  }
}
