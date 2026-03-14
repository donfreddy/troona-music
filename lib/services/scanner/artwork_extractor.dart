import 'dart:async';
import 'dart:io';

import 'package:on_audio_query_pluse/on_audio_query.dart';
import 'package:troona/features/library/data/models/track_model.dart';

/// Extracts and caches cover artwork for a list of [TrackModel]s.
///
/// Artwork is fetched from the platform media store via [OnAudioQuery] and
/// written as JPEG files to [cacheDir]. A [_Semaphore] limits concurrency to
/// [_maxConcurrent] parallel extractions so I/O and memory pressure stay
/// manageable on low-end devices.
///
/// **Stream ordering**: results are emitted as each extraction completes,
/// not in the original input order. This maximises throughput and gives the
/// [MediaScannerService] a steadier stream of progress events.
///
/// **Cancellation**: call [cancel] to stop dispatching new extraction tasks.
/// In-flight tasks are allowed to finish naturally (Dart [Future]s cannot be
/// cancelled mid-flight).
final class ArtworkExtractor {
  final OnAudioQuery _query;
  final Directory _cacheDir;

  /// Maximum number of concurrent artwork extractions.
  static const int _maxConcurrent = 4;

  bool _cancelRequested = false;

  /// Tracks extractions currently in progress, keyed by [TrackModel.deviceId].
  ///
  /// Prevents duplicate I/O when the same track appears more than once in the
  /// input list (e.g. during a partial re-scan). A second caller for the same
  /// key waits on the existing [Future] instead of racing on the cache file.
  final Map<String, Future<TrackModel>> _inFlight = {};

  ArtworkExtractor({required OnAudioQuery query, required Directory cacheDir})
    : _query = query,
      _cacheDir = cacheDir;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Requests cancellation: no new extraction tasks will be started after the
  /// current batch of up to [_maxConcurrent] tasks completes.
  void cancel() => _cancelRequested = true;

  /// Extracts artwork for each track in [tracks] and yields each [TrackModel]
  /// (with [TrackModel.artworkPath] populated if artwork was found) as soon as
  /// its extraction finishes.
  ///
  /// Tracks are processed with up to [_maxConcurrent] concurrent operations.
  /// Results arrive in **completion order**, not input order.
  Stream<TrackModel> extractArtworks(List<TrackModel> tracks) async* {
    _cancelRequested = false;

    // StreamController lets us emit results as futures complete rather than
    // waiting for each one in sequence.
    final controller = StreamController<TrackModel>();
    final semaphore = _Semaphore(_maxConcurrent);
    var remaining = tracks.length;

    if (remaining == 0) return;

    for (final track in tracks) {
      if (_cancelRequested) {
        // Drain the counter for skipped tracks so the controller closes.
        remaining--;
        if (remaining == 0) await controller.close();
        continue;
      }

      // Acquire semaphore slot (suspends when _maxConcurrent slots are busy).
      await semaphore.acquire();

      // Schedule the extraction without awaiting — results arrive via the
      // controller as each Future resolves.
      _extractForTrack(track)
          .then((updated) {
            semaphore.release();
            if (!controller.isClosed) controller.add(updated);
            remaining--;
            if (remaining == 0) controller.close();
          })
          .catchError((Object e) {
            semaphore.release();
            // Emit the original track unchanged so callers can count progress.
            if (!controller.isClosed) controller.add(track);
            remaining--;
            if (remaining == 0) controller.close();
          });
    }

    yield* controller.stream;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<TrackModel> _extractForTrack(TrackModel track) {
    // If an extraction is already running for this deviceId, reuse its Future
    // instead of launching a parallel write to the same cache file.
    return _inFlight.putIfAbsent(track.deviceId, () => _doExtract(track));
  }

  Future<TrackModel> _doExtract(TrackModel track) async {
    try {
      // Return immediately if artwork is already cached on disk.
      final cacheFile = File('${_cacheDir.path}/${track.deviceId}.jpg');
      if (await cacheFile.exists()) {
        return track..artworkPath = cacheFile.path;
      }

      // Attempt extraction via the platform media store.
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

      // No artwork available for this track.
      return track;
    } finally {
      // Always evict from the in-flight map so future calls (e.g. after a
      // failed extraction) can retry cleanly.
      _inFlight.remove(track.deviceId);
    }
  }
}

// ---------------------------------------------------------------------------
// Internal semaphore
// ---------------------------------------------------------------------------

/// A counting semaphore that limits the number of concurrent async operations.
///
/// Kept private to avoid adding an external dependency solely for this use case.
class _Semaphore {
  int _available;
  final List<Completer<void>> _waiters = [];

  _Semaphore(int maxConcurrent)
    : assert(maxConcurrent > 0),
      _available = maxConcurrent;

  /// Acquires one slot. Suspends the caller when all slots are occupied.
  Future<void> acquire() {
    if (_available > 0) {
      _available--;
      return Future.value();
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    return completer.future;
  }

  /// Releases one slot and unblocks the next waiting caller, if any.
  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _available++;
    }
  }
}
