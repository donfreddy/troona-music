import 'dart:io';

import 'package:on_audio_query_pluse/on_audio_query.dart';
import 'package:troona/features/library/data/models/track_model.dart';

final class ArtworkExtractor {
  final OnAudioQuery _query;
  final Directory _cacheDir;
  static const _maxConcurrent = 4; // Semaphore — 4 extractions en parallèle max

  ArtworkExtractor({required OnAudioQuery query, required Directory cacheDir}) : _query = query, _cacheDir = cacheDir;

  /// Extrait et cache les artworks pour une liste de tracks.
  /// Utilise un semaphore pour ne pas saturer l'I/O.
  Stream<TrackModel> extractArtworks(List<TrackModel> tracks) async* {
    final semaphore = Semaphore(_maxConcurrent);

    final futures = tracks.map((track) async {
      await semaphore.acquire();
      try {
        final updated = await _extractForTrack(track);
        return updated;
      } finally {
        semaphore.release();
      }
    });

    // Émet chaque track au fur et à mesure que son artwork est prêt
    for (final future in futures) {
      yield await future;
    }
  }

  Future<TrackModel> _extractForTrack(TrackModel track) async {
    // 1. Vérifie si le cache existe déjà
    final cacheFile = File('${_cacheDir.path}/${track.deviceId}.jpg');
    if (await cacheFile.exists()) {
      return track..artworkPath = cacheFile.path;
    }

    // 2. Tente l'extraction via on_audio_query
    final bytes = await _query.queryArtwork(
      int.parse(track.deviceId),
      ArtworkType.AUDIO,
      format: ArtworkFormat.JPEG,
      size: 500,
      quality: 85,
    );

    if (bytes != null && bytes.isNotEmpty) {
      await cacheFile.writeAsBytes(bytes);
      return track..artworkPath = cacheFile.path;
    }

    // 3. Fallback : lecture ID3 directe avec flutter_media_metadata
    return _fallbackID3Artwork(track, cacheFile);
  }

  Future<TrackModel> _fallbackID3Artwork(TrackModel track, File cacheFile) async {
    try {
      final metadata = await MetadataRetriever.fromFile(File(track.path));
      final bytes = metadata.albumArt;
      if (bytes != null && bytes.isNotEmpty) {
        await cacheFile.writeAsBytes(bytes);
        return track..artworkPath = cacheFile.path;
      }
    } catch (_) {
      // Silence — certains fichiers n'ont tout simplement pas d'artwork
    }
    return track; // artworkPath reste null
  }
}
