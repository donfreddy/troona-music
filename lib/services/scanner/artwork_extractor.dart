import 'dart:async';
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
    final semaphore = _Semaphore(_maxConcurrent);

    final futures = tracks.map((track) async {
      await semaphore.acquire();
      try {
        final updated = await _extractForTrack(track);
        return updated;
      } finally {
        semaphore.release();
      }
    }).toList();

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

    // Pas d'artwork disponible
    return track;
  }

}

/// Petite implémentation locale d'un sémaphore pour limiter la concurrence.
/// Évite d'ajouter une dépendance externe uniquement pour ce besoin.
class _Semaphore {
  int _available;
  final List<Completer<void>> _waiters = [];

  _Semaphore(this._available) : assert(_available > 0);

  Future<void> acquire() {
    if (_available > 0) {
      _available--;
      return Future.value();
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    return completer.future;
  }

  void release() {
    _available++;
    if (_waiters.isNotEmpty && _available > 0) {
      _available--;
      _waiters.removeAt(0).complete();
    }
  }
}
