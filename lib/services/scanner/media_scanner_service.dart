import 'package:troona/features/library/data/sources/local_audio_data_source.dart';
import 'package:troona/features/library/models/track_model.dart';
import 'package:troona/services/scanner/artwork_extractor.dart';

final class MediaScannerService {
  final LocalAudioDataSource _source;
  final IsarLibraryDataSource _cache;
  final ArtworkExtractor _artworkExtractor;

  MediaScannerService({
    required LocalAudioDataSource source,
    required IsarLibraryDataSource cache,
    required ArtworkExtractor artworkExtractor,
  }) : _source = source,
       _cache = cache,
       _artworkExtractor = artworkExtractor;

  /// Scan complet : détecte les nouveaux fichiers, supprime les orphelins.
  /// Yield ScanProgress pour que l'UI puisse afficher une barre de progression.
  Stream<ScanProgress> scanLibrary() async* {
    yield const ScanProgress(phase: ScanPhase.scanning, progress: 0);

    // 1. Récupère tous les tracks du device
    final List<TrackModel> scanned = [];
    await for (final chunk in _source.scanTracks()) {
      scanned.addAll(chunk);
      yield ScanProgress(
        phase: ScanPhase.scanning,
        progress: 0, // inconnu tant qu'on n'a pas le total
        count: scanned.length,
      );
    }

    yield ScanProgress(phase: ScanPhase.indexing, progress: 0, total: scanned.length);

    // 2. Diff avec le cache Isar — insère seulement les nouveaux
    final existingIds = await _cache.getAllDeviceIds();
    final newTracks = scanned.where((t) => !existingIds.contains(t.deviceId)).toList();
    final orphanIds = existingIds.difference(scanned.map((t) => t.deviceId).toSet());

    // Supprime les fichiers qui n'existent plus sur le device
    if (orphanIds.isNotEmpty) {
      await _cache.deleteByDeviceIds(orphanIds.toList());
    }

    // 3. Insère les nouveaux par batch
    const batchSize = 100;
    for (var i = 0; i < newTracks.length; i += batchSize) {
      final batch = newTracks.skip(i).take(batchSize).toList();
      await _cache.insertTracks(batch);

      yield ScanProgress(
        phase: ScanPhase.indexing,
        progress: (i + batch.length) / newTracks.length,
        total: newTracks.length,
        count: i + batch.length,
      );
    }

    // 4. Extraction artworks en arrière-plan (ne bloque pas l'UI)
    yield const ScanProgress(phase: ScanPhase.artworks, progress: 0);
    final tracksWithoutArtwork = await _cache.getTracksWithoutArtwork();
    var done = 0;

    await for (final updated in _artworkExtractor.extractArtworks(tracksWithoutArtwork)) {
      await _cache.updateArtworkPath(updated.deviceId, updated.artworkPath);
      done++;
      yield ScanProgress(
        phase: ScanPhase.artworks,
        progress: done / tracksWithoutArtwork.length,
        total: tracksWithoutArtwork.length,
        count: done,
      );
    }

    yield const ScanProgress(phase: ScanPhase.done, progress: 1);
  }
}

// ── Value objects ─────────────────────────────────────────

enum ScanPhase { scanning, indexing, artworks, done }

final class ScanProgress {
  final ScanPhase phase;
  final double progress; // 0.0 → 1.0
  final int count;
  final int total;
  const ScanProgress({required this.phase, required this.progress, this.count = 0, this.total = 0});
}
