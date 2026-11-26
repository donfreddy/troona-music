import 'dart:math' as math;

import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/mix_settings.dart';
import 'package:troona/features/player/domain/entities/track_edges.dart';

/// When and how the next song comes in under the one playing.
///
/// Positions are in the songs' own time: a speed change moves them all
/// alike.
final class TransitionPlan {
  const TransitionPlan({
    required this.outAt,
    required this.end,
    required this.inFrom,
    this.leavingFades = true,
    this.fastEntry = false,
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

  /// Whether the song leaving is faded down over the whole overlap; false
  /// when it fades out by itself: it then keeps its volume until the next
  /// song is at full volume, and is faded to nothing over the rest, so it
  /// never stops while still heard.
  final bool leavingFades;

  /// Whether the next song reaches its full volume at 60 % of the overlap
  /// ([TransitionPlanner.fastEntryAt]) rather than at its end.
  final bool fastEntry;

  /// The gains of the song leaving and of the one coming at [position]
  /// of the song leaving. The song leaving is always at 0 at [end].
  (double leaving, double coming) gainsAt(Duration position) {
    const at = TransitionPlanner.fastEntryAt;
    final t = progressAt(position);
    final (_, coming) = TransitionPlanner.equalPower(
      fastEntry ? math.min(1, t / at) : t,
    );
    final (leaving, _) = TransitionPlanner.equalPower(
      leavingFades ? t : math.max(0, (t - at) / (1 - at)),
    );
    return (leaving, coming);
  }

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
      other.inFrom == inFrom &&
      other.leavingFades == leavingFades &&
      other.fastEntry == fastEntry;

  @override
  int get hashCode => Object.hash(outAt, end, inFrom, leavingFades, fastEntry);

  @override
  String toString() =>
      'TransitionPlan(outAt: $outAt, end: $end, inFrom: $inFrom, '
      'leavingFades: $leavingFades, fastEntry: $fastEntry)';
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

  /// A song fading out by itself must leave the next one at least this
  /// long to come in; a shorter drop is an ending, faded as any other.
  static const minSelfFade = Duration(seconds: 2);

  /// With [TransitionPlan.fastEntry], where in the overlap the next song
  /// is at full volume.
  static const fastEntryAt = 0.6;

  /// How [next] comes in after [current], whose file lasts [length]; null
  /// when it simply follows, gapless.
  ///
  /// Never more than a third of either song: an interlude of 20 s must not
  /// spend its whole length fading.
  ///
  /// With smart transitions, the songs' edges, when known, move it: the
  /// song leaving ends where its music does ([currentEdges]), and the one
  /// coming starts after its silence ([nextEdges]). A song that fades out by itself
  /// keeps its volume: the next one comes in once it is down by 9 dB.
  /// Without edges, the files' lengths. Either way, the overlap set is the
  /// longest the two songs play together.
  static TransitionPlan? plan({
    required Track current,
    required Duration length,
    required Track next,
    required MixSettings settings,
    TrackEdges? currentEdges,
    TrackEdges? nextEdges,
  }) {
    if (!settings.crossfade) return null;
    if (settings.keepAlbumsWhole && followsOnAlbum(current, next)) return null;
    final leaving = settings.smart ? currentEdges : null;
    final coming = settings.smart ? nextEdges : null;

    var end = length - tailMargin;
    if (leaving != null && leaving.musicEnd < end) end = leaving.musicEnd;
    final inFrom = coming?.musicStart ?? Duration.zero;
    final nextLength = Duration(milliseconds: next.durationMs) - inFrom;

    final fadeDown = leaving?.fadeDown;
    if (fadeDown != null &&
        end - fadeDown >= minSelfFade &&
        fadeDown >= end - end ~/ 3) {
      final overlap = _shortest([
        settings.overlap,
        end - fadeDown,
        nextLength ~/ 3,
      ]);
      if (overlap >= minOverlap) {
        return TransitionPlan(
          outAt: fadeDown,
          end: fadeDown + overlap,
          inFrom: inFrom,
          leavingFades: false,
          fastEntry: true,
        );
      }
    }

    final overlap = _shortest([settings.overlap, end ~/ 3, nextLength ~/ 3]);
    if (overlap < minOverlap) return null;
    // The plain equal power: a song may stop at full level, and a faster
    // entry would make the middle louder.
    return TransitionPlan(outAt: end - overlap, end: end, inFrom: inFrom);
  }

  static Duration _shortest(List<Duration> lengths) =>
      lengths.reduce((x, y) => x < y ? x : y);

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
