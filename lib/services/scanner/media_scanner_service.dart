import 'package:troona/features/library/data/models/track_model.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/data/sources/local_audio_data_source.dart';
import 'package:troona/services/scanner/artwork_extractor.dart';

/// Orchestrates a four-phase incremental library scan:
///
/// 1. **Scanning** — query the device media store for all audio files.
/// 2. **Indexing** — diff the results against the Isar cache, insert new
///    tracks in batches, and delete orphaned entries.
/// 3. **Artworks** — extract and cache artwork for tracks that have none yet.
/// 4. **Done** — emit a final [ScanProgress] with `progress == 1.0`.
///
/// Progress is reported via a [Stream<ScanProgress>] so the UI can display
/// a live scan banner without coupling to implementation details.
///
/// **Cancellation**: call [cancel] at any time to request an early exit.
/// The stream stops emitting after the current in-flight batch completes.
/// [ArtworkExtractor] is also notified so it stops dispatching new tasks.
final class MediaScannerService {
  final LocalAudioDataSource _source;
  final IsarLibraryDataSource _cache;
  final ArtworkExtractor _artworkExtractor;

  bool _cancelRequested = false;

  MediaScannerService({
    required LocalAudioDataSource source,
    required IsarLibraryDataSource cache,
    required ArtworkExtractor artworkExtractor,
  }) : _source = source,
       _cache = cache,
       _artworkExtractor = artworkExtractor;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Requests cancellation of an in-progress scan.
  ///
  /// The current batch completes before the stream terminates.
  /// Safe to call when no scan is active.
  void cancel() {
    _cancelRequested = true;
    _artworkExtractor.cancel();
  }

  /// Starts an incremental library scan and returns a cold [Stream] of
  /// [ScanProgress] events.
  ///
  /// The stream completes normally after all phases or after [cancel] is called.
  Stream<ScanProgress> scanLibrary() async* {
    _cancelRequested = false;

    // ── Phase 1: query device ───────────────────────────────────────────────
    yield const ScanProgress(phase: ScanPhase.scanning, progress: 0);

    final List<TrackModel> scanned = [];
    await for (final chunk in _source.scanTracks()) {
      scanned.addAll(chunk);
      yield ScanProgress(
        phase: ScanPhase.scanning,
        progress: 0,
        count: scanned.length,
      );
      if (_cancelRequested) {
        yield const ScanProgress(phase: ScanPhase.done, progress: 1.0);
        return;
      }
    }

    if (_cancelRequested) {
      yield const ScanProgress(phase: ScanPhase.done, progress: 1.0);
      return;
    }

    // ── Phase 2: diff + index ───────────────────────────────────────────────
    yield ScanProgress(
      phase: ScanPhase.indexing,
      progress: 0,
      total: scanned.length,
    );

    final existingIds = await _cache.getAllDeviceIds();
    final newTracks = scanned
        .where((t) => !existingIds.contains(t.deviceId))
        .toList();
    final orphanIds = existingIds.difference(
      scanned.map((t) => t.deviceId).toSet(),
    );

    if (orphanIds.isNotEmpty) {
      await _cache.deleteByDeviceIds(orphanIds.toList());
    }

    const batchSize = 100;
    final newTotal = newTracks.length.clamp(1, newTracks.length);
    for (var i = 0; i < newTracks.length; i += batchSize) {
      if (_cancelRequested) {
        yield const ScanProgress(phase: ScanPhase.done, progress: 1.0);
        return;
      }
      final batch = newTracks.skip(i).take(batchSize).toList();
      await _cache.insertTracks(batch);

      yield ScanProgress(
        phase: ScanPhase.indexing,
        progress: (i + batch.length) / newTotal,
        total: newTracks.length,
        count: i + batch.length,
      );
    }

    if (_cancelRequested) {
      yield const ScanProgress(phase: ScanPhase.done, progress: 1.0);
      return;
    }

    // ── Phase 3: artwork extraction ─────────────────────────────────────────
    yield const ScanProgress(phase: ScanPhase.artworks, progress: 0);

    final tracksWithoutArtwork = await _cache.getTracksWithoutArtwork();
    final artworkTotal = tracksWithoutArtwork.length;
    var done = 0;

    await for (final updated in _artworkExtractor.extractArtworks(
      tracksWithoutArtwork,
    )) {
      if (_cancelRequested) {
        yield const ScanProgress(phase: ScanPhase.done, progress: 1.0);
        return;
      }
      if (updated.artworkPath != null) {
        await _cache.updateArtworkPath(updated.deviceId, updated.artworkPath!);
      }
      done++;
      yield ScanProgress(
        phase: ScanPhase.artworks,
        progress: artworkTotal == 0 ? 1.0 : done / artworkTotal,
        total: artworkTotal,
        count: done,
      );
    }

    // ── Phase 4: done ───────────────────────────────────────────────────────
    yield const ScanProgress(phase: ScanPhase.done, progress: 1.0);
  }
}

// ---------------------------------------------------------------------------
// Value objects
// ---------------------------------------------------------------------------

/// The phase of an active library scan.
enum ScanPhase {
  /// Querying the device media store.
  scanning,

  /// Writing new tracks to the Isar cache and removing orphaned entries.
  indexing,

  /// Extracting and caching cover artwork.
  artworks,

  /// All phases complete.
  done,
}

/// Snapshot of scan progress emitted by [MediaScannerService.scanLibrary].
final class ScanProgress {
  /// The current scan phase.
  final ScanPhase phase;

  /// A value in `[0.0, 1.0]` representing progress within [phase].
  /// May be 0 during [ScanPhase.scanning] when the total is still unknown.
  final double progress;

  /// Number of items processed in the current phase so far.
  final int count;

  /// Total items to process in the current phase (0 when unknown).
  final int total;

  const ScanProgress({
    required this.phase,
    required this.progress,
    this.count = 0,
    this.total = 0,
  });
}
