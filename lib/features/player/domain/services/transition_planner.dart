import 'dart:math' as math;

import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/mix_settings.dart';

/// When and how the next song comes in under the one playing.
///
/// Positions are in the songs' own time: a speed change moves them all
/// alike.
final class TransitionPlan {
  const TransitionPlan({
    required this.outAt,
    required this.end,
    required this.inFrom,
  });

  /// Where, in the song leaving, the next one starts.
  final Duration outAt;

  /// Where, in the song leaving, the transition is over: that song stops
  /// there.
  final Duration end;

  /// Where the next song starts from.
  final Duration inFrom;

  /// How long both play together.
  Duration get overlap => end - outAt;

  /// How far into the transition [position] (of the song leaving) is,
  /// from 0 to 1.
  double progressAt(Duration position) =>
      ((position - outAt).inMicroseconds / overlap.inMicroseconds).clamp(
        0.0,
        1.0,
      );

  @override
  bool operator ==(Object other) =>
      other is TransitionPlan &&
      other.outAt == outAt &&
      other.end == end &&
      other.inFrom == inFrom;

  @override
  int get hashCode => Object.hash(outAt, end, inFrom);

  @override
  String toString() =>
      'TransitionPlan(outAt: $outAt, end: $end, inFrom: $inFrom)';
}

/// Plans the transitions between songs.
abstract final class TransitionPlanner {
  TransitionPlanner._();

  /// Below this, an overlap is a glitch rather than a transition.
  static const minOverlap = Duration(seconds: 1);

  /// The song leaving stops this long before its file ends: its player
  /// still holds the queue, and would move on to the next song by itself.
  /// Its gain is down to nothing by then.
  static const tailMargin = Duration(milliseconds: 300);

  /// How [next] comes in after [current], whose file lasts [length]; null
  /// when it simply follows, gapless.
  ///
  /// Never more than a third of either song: an interlude of 20 s must not
  /// spend its whole length fading.
  static TransitionPlan? plan({
    required Track current,
    required Duration length,
    required Track next,
    required MixSettings settings,
  }) {
    if (!settings.crossfade) return null;
    if (settings.keepAlbumsWhole && followsOnAlbum(current, next)) return null;
    final end = length - tailMargin;
    final nextLength = Duration(milliseconds: next.durationMs);
    final overlap = [
      settings.overlap,
      end ~/ 3,
      nextLength ~/ 3,
    ].reduce((x, y) => x < y ? x : y);
    if (overlap < minOverlap) return null;
    return TransitionPlan(
      outAt: end - overlap,
      end: end,
      inFrom: Duration.zero,
    );
  }

  /// Whether [next] is the song after [current] on their album.
  ///
  /// By track numbers (MediaStore files the disc in the thousands): the
  /// next number, or the first of the next disc. Songs without one never
  /// follow: MediaStore makes an album of a folder whose songs have no
  /// album tag, so a folder of downloaded singles would never fade.
  static bool followsOnAlbum(Track current, Track next) {
    if (current.albumId != next.albumId || current.id == next.id) {
      return false;
    }
    final a = current.trackNumber;
    final b = next.trackNumber;
    if (a == null || b == null || a % 1000 == 0 || b % 1000 == 0) {
      return false;
    }
    final (discA, numberA) = (a ~/ 1000, a % 1000);
    final (discB, numberB) = (b ~/ 1000, b % 1000);
    if (discA == discB) return numberB == numberA + 1;
    return discB == discA + 1 && numberB == 1;
  }

  /// The gains of the song leaving and of the one coming at [t] (0 to 1)
  /// of the overlap: their powers add up to one, so the level stays even
  /// (two unrelated signals add in power, and a linear fade dips in the
  /// middle).
  static (double leaving, double coming) equalPower(double t) {
    final x = t.clamp(0.0, 1.0) * math.pi / 2;
    return (math.cos(x), math.sin(x));
  }
}
