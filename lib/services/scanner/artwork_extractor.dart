import 'dart:async';
import 'dart:io';

import 'package:on_audio_query_pluse/on_audio_query.dart';
import 'package:troona/features/library/data/models/track_model.dart';

/// Outcome of one extraction. [checked] is false when the extraction failed,
/// so the track is tried again on the next scan.
final class ArtworkResult {
  final String deviceId;
  final String? artworkPath;
  final bool checked;

  const ArtworkResult(this.deviceId, this.artworkPath) : checked = true;
  const ArtworkResult.failed(this.deviceId)
    : artworkPath = null,
      checked = false;
}

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

  /// The root directory where extracted artwork JPEG files are stored.
  Directory get cacheDir => _cacheDir;

  /// Extracts artwork for each track in [tracks] and emits one
  /// [ArtworkResult] per track as soon as its extraction finishes.
  ///
  /// Tracks are processed with up to [_maxConcurrent] concurrent operations.
  /// Results arrive in **completion order**, not input order. The stream is
  /// returned before any work is dispatched, so the first results reach the
  /// listener while later tracks are still waiting for a slot.
  Stream<ArtworkResult> extractArtworks(List<TrackModel> tracks) {
    _cancelRequested = false;
    final controller = StreamController<ArtworkResult>();
    unawaited(_dispatch(tracks, controller));
    return controller.stream;
  }

  Future<void> _dispatch(
    List<TrackModel> tracks,
    StreamController<ArtworkResult> controller,
  ) async {
    final semaphore = _Semaphore(_maxConcurrent);
    final running = <Future<void>>[];

    for (final track in tracks) {
      await semaphore.acquire();
      if (_cancelRequested) {
        semaphore.release();
        break;
      }
      running.add(
        _extractForTrack(track)
            .then<ArtworkResult>(
              (updated) => ArtworkResult(track.deviceId, updated.artworkPath),
            )
            // A failure is not "no artwork": leave the track for next scan.
            .catchError((Object _) => ArtworkResult.failed(track.deviceId))
            .then((result) {
              semaphore.release();
              if (!controller.isClosed) controller.add(result);
            }),
      );
    }

    await Future.wait(running);
    await controller.close();
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
