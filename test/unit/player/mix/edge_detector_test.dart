import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/player/domain/entities/track_edges.dart';
import 'package:troona/features/player/domain/services/edge_detector.dart';

/// A song of 200 s analysed as the app does: its first 10 s and its last
/// 30 s (from 170 s), in windows of 50 ms.
void main() {
  const window = Duration(milliseconds: 50);
  const headWindows = 200;
  const tailWindows = 600;
  const tailFrom = Duration(seconds: 170);

  /// The time of tail window [k].
  Duration tailAt(int k) => tailFrom + window * k;

  TrackEnvelope envelope({
    double Function(int k)? head,
    double Function(int k)? tail,
  }) => TrackEnvelope(
    duration: const Duration(seconds: 200),
    window: window,
    head: [for (var k = 0; k < headWindows; k++) head?.call(k) ?? -10],
    tailFrom: tailFrom,
    tail: [for (var k = 0; k < tailWindows; k++) tail?.call(k) ?? -10],
  );

  Matcher near(Duration d, {int ms = 300}) => predicate<Duration>(
    (v) => (v - d).abs() <= Duration(milliseconds: ms),
    'within $ms ms of $d',
  );

  test('music from the first window to the last: the whole file', () {
    final edges = EdgeDetector.detect(envelope());
    expect(edges.musicStart, Duration.zero);
    expect(edges.musicEnd, const Duration(seconds: 200));
    expect(edges.fadeDown, isNull);
  });

  test('a silent start is skipped', () {
    final edges = EdgeDetector.detect(
      envelope(head: (k) => k < 30 ? -80 : -12),
    );
    expect(edges.musicStart, const Duration(milliseconds: 1500));
  });

  test('a click in the silence is not the start of the song', () {
    final edges = EdgeDetector.detect(
      envelope(
        head: (k) => k == 4
            ? -20
            : k < 30
            ? -80
            : -12,
      ),
    );
    expect(edges.musicStart, const Duration(milliseconds: 1500));
  });

  test('a quiet intro is music, not silence', () {
    // A soft opening at -55 dBFS for 2 s, then the song.
    final edges = EdgeDetector.detect(
      envelope(head: (k) => k < 40 ? -55 : -12),
    );
    expect(edges.musicStart, Duration.zero);
  });

  test('a silent end is cut', () {
    final edges = EdgeDetector.detect(
      envelope(tail: (k) => k < 520 ? -10 : -90),
    );
    expect(edges.musicEnd, tailAt(520));
    expect(edges.fadeDown, isNull);
  });

  test('windows holding no sample count as silence', () {
    final edges = EdgeDetector.detect(
      envelope(tail: (k) => k < 580 ? -10 : TrackEnvelope.noData),
    );
    expect(edges.musicEnd, tailAt(580));
  });

  test('a tail whose samples stop well before the file length is not '
      'trusted: the file is left whole', () {
    final edges = EdgeDetector.detect(
      envelope(
        tail: (k) => k < 500
            ? -10
            : k < 540
            ? -90
            : TrackEnvelope.noData,
      ),
    );
    expect(edges.musicEnd, const Duration(seconds: 200));
    expect(edges.fadeDown, isNull);
  });

  test('a quiet outro ends the music before the silence: a short drop is '
      'an ending, not a fade', () {
    final edges = EdgeDetector.detect(
      envelope(
        tail: (k) => k < 520
            ? -10
            : k < 560
            ? -40
            : -90,
      ),
    );
    expect(edges.musicEnd, near(tailAt(530)));
    expect(edges.musicEnd, lessThan(tailAt(560)));
    expect(edges.fadeDown, isNull);
  });

  test('a fade out: the next song comes in once it is 9 dB down, and the '
      'music ends once it is 24 dB down', () {
    // From -10 dB at 190 s to -60 dB at 198 s, then silence.
    final edges = EdgeDetector.detect(
      envelope(
        tail: (k) => k < 400
            ? -10
            : k < 560
            ? -10 - 50 * (k - 400) / 160
            : -90,
      ),
    );
    // 9 dB down at window 428.8, 24 dB down at window 476.8.
    expect(edges.fadeDown, near(tailAt(429)));
    expect(edges.musicEnd, near(tailAt(477)));
  });

  test('a fade into steady noise is still a fade', () {
    // Down to a hiss at -45 dB: never silence, but far under the body.
    final edges = EdgeDetector.detect(
      envelope(
        tail: (k) => k < 400
            ? -10
            : k < 500
            ? -10 - 35 * (k - 400) / 100
            : -45,
      ),
    );
    expect(edges.fadeDown, isNotNull);
    expect(edges.musicEnd, lessThan(const Duration(seconds: 200)));
  });

  test('a song quiet all along is judged against its own level', () {
    final quiet = EdgeDetector.detect(
      envelope(head: (_) => -30, tail: (_) => -30),
    );
    expect(quiet.musicEnd, const Duration(seconds: 200));
    expect(quiet.fadeDown, isNull);
  });

  test('a tail with no music at all leaves the file whole', () {
    final edges = EdgeDetector.detect(envelope(tail: (_) => -90));
    expect(edges.musicEnd, const Duration(seconds: 200));
    expect(edges.fadeDown, isNull);
  });
}
