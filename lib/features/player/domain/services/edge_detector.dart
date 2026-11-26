import 'dart:math' as math;

import 'package:troona/features/player/domain/entities/track_edges.dart';

/// Finds where a song's music starts and stops in its [TrackEnvelope].
///
/// The thresholds were set by ear on a real library. Silence is an
/// absolute level, set low so that a quiet intro or outro is never taken
/// for it; the end of the music and a fade are judged against the song's
/// own body, the median of the first third of its tail, so a quiet song
/// and a loud one are judged alike.
abstract final class EdgeDetector {
  EdgeDetector._();

  /// Below this, a window is silence: low enough for a quiet classical
  /// intro, high enough for a vinyl rip's noise.
  static const silence = -60.0;

  /// The music starts with this many windows in a row above [silence]:
  /// a click is not the start of a song.
  static const startRun = 3;

  /// The tail is not trusted when its samples stop this long before the
  /// file's length: the decoder then placed them by an estimate (a
  /// variable bitrate file with no index), and the player will not play
  /// them at those times.
  static const maxShortfall = Duration(seconds: 1);

  /// The music is over once it stays this far under the song's body.
  static const quietBelow = 24.0;

  /// A fade starts this far under the body...
  static const fadeStartsBelow = 3.0;

  /// ...the next song comes in once it is this far under...
  static const fadeDownBelow = 9.0;

  /// ...and it must be this far under [_nearEnd] before the end.
  static const fadeEndsBelow = 15.0;

  /// A fade lasts at least this long; a shorter drop is an ending.
  static const minFade = Duration(seconds: 3);

  static const _nearEnd = Duration(milliseconds: 500);

  /// The levels are averaged over this span before looking for a fade or
  /// a quiet end: a drum hit or a pause between two notes is not one.
  static const _smoothing = Duration(seconds: 1);

  static TrackEdges detect(TrackEnvelope envelope) {
    final window = envelope.window.inMicroseconds;
    final head = envelope.head;
    final tail = envelope.tail;
    Duration at(Duration from, int windows) =>
        from + Duration(microseconds: windows * window);

    final musicStart = _start(head, envelope.window);

    final lastSample = tail.lastIndexWhere((db) => db > TrackEnvelope.noData);
    final last = tail.lastIndexWhere((db) => db > silence);
    if (last < 0 ||
        envelope.duration - at(envelope.tailFrom, lastSample + 1) >
            maxShortfall) {
      return TrackEdges(musicStart: musicStart, musicEnd: envelope.duration);
    }
    final silenceFrom = _min(
      at(envelope.tailFrom, last + 1),
      envelope.duration,
    );

    final levels = [
      for (var k = 0; k < tail.length ~/ 3; k++)
        if (tail[k] > TrackEnvelope.noData) tail[k],
    ]..sort();
    if (last == 0 || levels.isEmpty) {
      return TrackEdges(musicStart: musicStart, musicEnd: silenceFrom);
    }
    final body = levels[levels.length ~/ 2];
    final smooth = _smooth(
      tail,
      math.max(1, _smoothing.inMicroseconds ~/ window),
    );

    var quiet = last;
    while (quiet > 0 && smooth[quiet] < body - quietBelow) {
      quiet--;
    }
    final musicEnd = _min(silenceFrom, at(envelope.tailFrom, quiet + 1));

    var from = last;
    while (from > 0 && smooth[from] < body - fadeStartsBelow) {
      from--;
    }
    var down = from;
    while (down < last && smooth[down] > body - fadeDownBelow) {
      down++;
    }
    final nearEnd =
        smooth[math.max(0, last - _nearEnd.inMicroseconds ~/ window)];
    final fades =
        (last - from) * window >= minFade.inMicroseconds &&
        nearEnd <= body - fadeEndsBelow;
    final fadeDown = at(envelope.tailFrom, down);
    return TrackEdges(
      musicStart: musicStart,
      musicEnd: musicEnd,
      fadeDown: fades && fadeDown < musicEnd ? fadeDown : null,
    );
  }

  static Duration _min(Duration a, Duration b) => a < b ? a : b;

  /// Where [startRun] windows in a row are above [silence]; the file's
  /// start when none are.
  static Duration _start(List<double> head, Duration window) {
    var run = 0;
    for (var k = 0; k < head.length; k++) {
      run = head[k] > silence ? run + 1 : 0;
      if (run == startRun) return window * (k - startRun + 1);
    }
    return Duration.zero;
  }

  /// [levels] averaged in power over [span] windows, back in dB.
  static List<double> _smooth(List<double> levels, int span) {
    final half = math.max(1, span ~/ 2);
    return [
      for (var k = 0; k < levels.length; k++)
        () {
          var sum = 0.0;
          var count = 0;
          final end = math.min(levels.length, k + half);
          for (var j = math.max(0, k - half); j < end; j++) {
            if (levels[j] <= TrackEnvelope.noData) continue;
            sum += math.pow(10, levels[j] / 10);
            count++;
          }
          return count == 0 || sum <= 0
              ? -120.0
              : 10 * math.log(sum / count) / math.ln10;
        }(),
    ];
  }
}
