import 'dart:async';

import 'package:flutter/services.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/track_edges.dart';
import 'package:troona/features/player/domain/ports/track_edge_analyzer.dart';

/// [TrackEdgeAnalyzer] over the Android decoder (`TrackEdgesChannel.kt`).
final class PlatformTrackEdgeAnalyzer implements TrackEdgeAnalyzer {
  static const channel = MethodChannel('troona/track_edges');

  /// What is decoded: enough of the start for a silent intro, enough of
  /// the end for a long fade out.
  static const head = Duration(seconds: 10);
  static const tail = Duration(seconds: 30);
  static const window = Duration(milliseconds: 50);

  /// The decoder gives up after 30 s; this is in case it never answers.
  static const timeout = Duration(seconds: 45);

  @override
  Future<TrackEnvelope> envelopeOf(Track track) async {
    final Map<String, Object?>? map;
    try {
      map = await channel
          .invokeMapMethod<String, Object?>('analyze', {
            'uri': track.uri,
            'path': track.path,
            'headMs': head.inMilliseconds,
            'tailMs': tail.inMilliseconds,
            'windowMs': window.inMilliseconds,
          })
          .timeout(timeout);
    } on PlatformException catch (e) {
      if (e.code == 'unreadable') throw UnreadableTrack(e.message ?? e.code);
      rethrow;
    }
    if (map == null) throw const UnreadableTrack('no answer');
    return envelopeFrom(map);
  }

  /// The envelope [map] describes; throws [UnreadableTrack] when it is
  /// not one.
  static TrackEnvelope envelopeFrom(Map<String, Object?> map) {
    final (duration, window, tailFrom) = (
      map['durationMs'],
      map['windowMs'],
      map['tailFromMs'],
    );
    final (head, tail) = (map['head'], map['tail']);
    if (duration is! int ||
        window is! int ||
        window <= 0 ||
        tailFrom is! int ||
        head is! List ||
        tail is! List) {
      throw const UnreadableTrack('malformed envelope');
    }
    List<double> levels(List<Object?> raw) => [
      for (final level in raw) level is num ? level.toDouble() : -200,
    ];
    return TrackEnvelope(
      duration: Duration(milliseconds: duration),
      window: Duration(milliseconds: window),
      head: levels(head),
      tailFrom: Duration(milliseconds: tailFrom),
      tail: levels(tail),
    );
  }
}
