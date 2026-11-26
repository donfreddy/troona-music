import 'dart:async';

import 'package:troona/core/error/error_handler.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/track_edges.dart';
import 'package:troona/features/player/domain/ports/audio_service_port.dart';
import 'package:troona/features/player/domain/repositories/track_edges_repository.dart';

/// Finds the edges of the song playing and of the next one ahead of their
/// transition, and keeps them for the player, which reads them at once
/// ([edgesOf]) rather than wait: analysing a song takes several seconds.
///
/// Only while [wanted] (crossfade and smart transitions on), one song at
/// a time, the song playing first (its end is the first needed). Never
/// the whole library: a song is analysed once, when it is about to play.
final class TrackEdgesPrefetcher {
  TrackEdgesPrefetcher({
    required AudioServicePort port,
    required TrackEdgesRepository repository,
    required bool Function() wanted,
    DateTime Function()? now,
  }) : _port = port,
       _repository = repository,
       _wanted = wanted,
       _now = now ?? DateTime.now;

  final AudioServicePort _port;
  final TrackEdgesRepository _repository;
  final bool Function() _wanted;
  final DateTime Function() _now;

  /// How many songs' edges are kept, the last found.
  static const _kept = 64;

  /// A song whose edges were not found is not asked again before this:
  /// the queue is published again on every play and pause, and a failure
  /// that may pass (a timeout, the channel not there yet) would decode
  /// the file each time. A file that cannot be read is remembered by the
  /// repository for good.
  static const retryAfter = Duration(minutes: 10);

  /// Edges found, by song id, the oldest first (a map literal keeps its
  /// order).
  final _known = <String, TrackEdges>{};

  /// Songs to analyse, in order; replaced on each change of the queue.
  final _pending = <Track>[];

  /// When each song whose edges were not found was last asked.
  final _missed = <String, DateTime>{};
  bool _running = false;
  StreamSubscription<Queue>? _queue;

  void start() => _queue ??= _port.queueStream.listen(_onQueue);

  Future<void> stop() async {
    await _queue?.cancel();
    _queue = null;
    _pending.clear();
  }

  /// [track]'s edges when they are known; null otherwise.
  TrackEdges? edgesOf(Track track) => _known[track.id];

  void _onQueue(Queue queue) {
    _pending.clear();
    if (!_wanted()) return;
    for (final track in [queue.currentTrack, queue.nextTrack]) {
      if (track == null || !_due(track.id)) continue;
      if (_pending.any((t) => t.id == track.id)) continue;
      _pending.add(track);
    }
    unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_running) return;
    _running = true;
    try {
      while (_pending.isNotEmpty) {
        final track = _pending.removeAt(0);
        if (!_due(track.id) || !_wanted()) continue;
        TrackEdges? edges;
        try {
          edges = await _repository.edgesOf(track);
        } catch (e, st) {
          ErrorHandler.handle(e, st);
        }
        if (edges != null) {
          _missed.remove(track.id);
          _remember(track.id, edges);
        } else {
          final now = _now();
          _missed
            ..removeWhere((_, at) => now.difference(at) >= retryAfter)
            ..[track.id] = now;
        }
      }
    } finally {
      _running = false;
    }
  }

  /// Whether [id] is worth asking: not known, and not missed within
  /// [retryAfter]. Checked again once the song before is done, so a song
  /// queued again during its own analysis is skipped then.
  bool _due(String id) {
    if (_known.containsKey(id)) return false;
    final missed = _missed[id];
    return missed == null || _now().difference(missed) >= retryAfter;
  }

  void _remember(String id, TrackEdges edges) {
    _known
      ..remove(id)
      ..[id] = edges;
    while (_known.length > _kept) {
      _known.remove(_known.keys.first);
    }
  }
}
