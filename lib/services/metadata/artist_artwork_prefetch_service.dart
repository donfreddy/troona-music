import 'dart:async';

import 'package:troona/core/utils/app_logger.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/artist_detail_repository.dart';
import 'package:troona/features/metadata/data/sources/deezer_artist_match.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';

/// Silent background service that downloads and caches artist portrait photos
/// for top artists and library artists without blocking the UI.
class ArtistArtworkPrefetchService {
  final MetadataRepository _repo;
  final ArtistDetailRepository _artists;
  final Set<String> _inFlight = {};

  ArtistArtworkPrefetchService({
    required MetadataRepository repo,
    required ArtistDetailRepository artists,
  }) : _repo = repo,
       _artists = artists;

  /// The titles a photo of [artistId] is looked for with, from [tracks]
  /// most played first: the songs they lead, since a song search names the
  /// lead artist only (a guest's song shows its host). Each song once, as
  /// [DeezerArtistMatch.titleKey] compares them ("Song" and "Song (Live)"
  /// are one search), none that compares as nothing ("(Interlude)").
  static List<String> songTitlesFor(String artistId, Iterable<Track> tracks) {
    final titles = <String>[];
    final keys = <String>{};
    for (final track in tracks) {
      if (track.artistId.toString() != artistId) continue;
      final title = track.title.trim();
      final key = DeezerArtistMatch.titleKey(title);
      if (key.isEmpty || !keys.add(key)) continue;
      titles.add(title);
    }
    return titles;
  }

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
        final songs = (await _artists.getTopTracksByArtistId(
          artist.id,
        )).fold((_) => const <Track>[], (s) => s.tracks);
        await _repo.prefetchArtistPhoto(
          artistId: artist.id,
          artistName: artist.name,
          songTitles: songTitlesFor(artist.id, songs),
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
