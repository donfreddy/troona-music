import 'dart:async';

import 'package:troona/core/utils/app_logger.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';

/// Silent background service that downloads and caches artist portrait photos
/// for top artists and library artists without blocking the UI.
class ArtistArtworkPrefetchService {
  final MetadataRepository _repo;
  final Set<String> _inFlight = {};

  ArtistArtworkPrefetchService({required MetadataRepository repo})
    : _repo = repo;

  /// Prefetches artist portraits in the background.
  /// Throttled by [delayMs] between network requests so it doesn't saturate Deezer/Last.fm.
  Future<void> prefetchArtists(
    List<Artist> artists, {
    int delayMs = 250,
  }) async {
    for (final artist in artists) {
      if (artist.id.isEmpty || artist.name.trim().isEmpty) continue;
      if (_inFlight.contains(artist.id)) continue;

      // Skip immediately if the HD photo is already downloaded on disk
      if (_repo.getCachedArtistArtworkPath(artist.id) != null) continue;

      _inFlight.add(artist.id);
      try {
        await _repo.prefetchArtistPhoto(
          artistId: artist.id,
          artistName: artist.name,
        );
      } catch (e) {
        appLogger.w(
          'ArtistArtworkPrefetchService: failed for ${artist.name}: $e',
        );
      } finally {
        _inFlight.remove(artist.id);
      }

      if (delayMs > 0) {
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }
}
