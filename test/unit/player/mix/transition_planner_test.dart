import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/mix_settings.dart';
import 'package:troona/features/player/domain/entities/track_edges.dart';
import 'package:troona/features/player/domain/services/transition_planner.dart';

Track _song(
  String id, {
  int durationMs = 200000,
  int albumId = 1,
  int? number,
}) => Track(
  id: id,
  title: id,
  artist: 'Artist',
  artistId: 1,
  album: 'Album $albumId',
  albumId: albumId,
  trackNumber: number,
  path: '/m/$id.mp3',
  uri: '',
  size: 1,
  durationMs: durationMs,
  fileName: '$id.mp3',
);

void main() {
  const on = MixSettings(crossfade: true);
  const s = Duration(seconds: 1);

  TransitionPlan? plan(
    Track current,
    Track next, {
    Duration length = const Duration(seconds: 200),
    MixSettings settings = on,
    TrackEdges? currentEdges,
    TrackEdges? nextEdges,
  }) => TransitionPlanner.plan(
    current: current,
    length: length,
    next: next,
    settings: settings,
    currentEdges: currentEdges,
    nextEdges: nextEdges,
  );

  TrackEdges edges({
    Duration start = Duration.zero,
    Duration end = const Duration(seconds: 200),
    Duration? fadeDown,
  }) => TrackEdges(musicStart: start, musicEnd: end, fadeDown: fadeDown);

  group('plan', () {
    test('off: the next song follows, gapless', () {
      expect(
        plan(_song('a'), _song('b', albumId: 2), settings: MixSettings.off),
        isNull,
      );
    });

    test('ends just before the file does, the overlap before that', () {
      final p = plan(_song('a'), _song('b', albumId: 2))!;
      final end = s * 200 - TransitionPlanner.tailMargin;
      expect(p.end, end);
      expect(p.outAt, end - s * 6);
      expect(p.overlap, s * 6);
      expect(p.inFrom, Duration.zero);
    });

    test('never more than a third of the song leaving', () {
      final p = plan(
        _song('a'),
        _song('b', albumId: 2),
        length: s * 9 + TransitionPlanner.tailMargin,
      )!;
      expect(p.overlap, s * 3);
    });

    test('never more than a third of the song coming', () {
      final p = plan(_song('a'), _song('b', albumId: 2, durationMs: 6000))!;
      expect(p.overlap, s * 2);
    });

    test('songs too short for a second of overlap simply follow', () {
      expect(
        plan(_song('a'), _song('b', albumId: 2, durationMs: 2900)),
        isNull,
      );
      expect(
        plan(
          _song('a'),
          _song('b', albumId: 2),
          length: const Duration(milliseconds: 3200),
        ),
        isNull,
      );
    });

    test('keeps an album whole when asked', () {
      final a = _song('a', number: 1);
      final b = _song('b', number: 2);
      expect(plan(a, b), isNull);
      expect(
        plan(
          a,
          b,
          settings: const MixSettings(crossfade: true, keepAlbumsWhole: false),
        ),
        isNotNull,
      );
    });

    test('the same album out of order still fades', () {
      expect(plan(_song('a', number: 5), _song('b', number: 2)), isNotNull);
    });
  });

  group('followsOnAlbum', () {
    final follows = TransitionPlanner.followsOnAlbum;

    test('the next number on the same album', () {
      expect(follows(_song('a', number: 3), _song('b', number: 4)), isTrue);
      expect(follows(_song('a', number: 3), _song('b', number: 5)), isFalse);
      expect(follows(_song('a', number: 4), _song('b', number: 3)), isFalse);
    });

    test('another album never follows', () {
      expect(
        follows(_song('a', number: 1), _song('b', number: 2, albumId: 9)),
        isFalse,
      );
    });

    test('the first song of the next disc follows the last of the one '
        'before', () {
      expect(
        follows(_song('a', number: 1012), _song('b', number: 2001)),
        isTrue,
      );
      expect(
        follows(_song('a', number: 1012), _song('b', number: 2003)),
        isFalse,
      );
      expect(
        follows(_song('a', number: 1003), _song('b', number: 1004)),
        isTrue,
      );
    });

    test('songs without a number never follow: a folder of singles is one '
        'album to MediaStore', () {
      expect(follows(_song('a'), _song('b')), isFalse);
      expect(follows(_song('a', number: 1), _song('b')), isFalse);
      expect(
        follows(_song('a', number: 2000), _song('b', number: 2001)),
        isFalse,
      );
    });

    test('a song does not follow itself (repeat)', () {
      final a = _song('a', number: 1);
      expect(follows(a, a), isFalse);
    });
  });

  group('equalPower', () {
    test('the ends: one song alone', () {
      final (outStart, inStart) = TransitionPlanner.equalPower(0);
      expect(outStart, 1);
      expect(inStart, 0);
      final (outEnd, inEnd) = TransitionPlanner.equalPower(1);
      expect(outEnd, closeTo(0, 1e-12));
      expect(inEnd, 1);
    });

    test('the powers add up to one all along: no dip in the middle', () {
      for (var i = 0; i <= 20; i++) {
        final (o, n) = TransitionPlanner.equalPower(i / 20);
        expect(o * o + n * n, closeTo(1, 1e-12));
      }
      final (o, n) = TransitionPlanner.equalPower(0.5);
      expect(o, closeTo(math.sqrt1_2, 1e-12));
      expect(n, closeTo(math.sqrt1_2, 1e-12));
    });

    test('out of range is clamped', () {
      expect(TransitionPlanner.equalPower(-1), TransitionPlanner.equalPower(0));
      expect(TransitionPlanner.equalPower(2), TransitionPlanner.equalPower(1));
    });
  });

  group('with edges', () {
    final a = _song('a');
    final b = _song('b', albumId: 2);

    test('the song leaving ends where its music does', () {
      final p = plan(a, b, currentEdges: edges(end: s * 190))!;
      expect(p.end, s * 190);
      expect(p.outAt, s * 184);
      expect(p.leavingFades, isTrue);
      // It may stop at full level: the plain equal power.
      expect(p.fastEntry, isFalse);
    });

    test('music up to the file end still stops before it', () {
      final p = plan(a, b, currentEdges: edges(end: s * 200))!;
      expect(p.end, s * 200 - TransitionPlanner.tailMargin);
    });

    test('the next song starts after its silence, a third of what is '
        'left at most', () {
      final p = plan(
        a,
        _song('b', albumId: 2, durationMs: 20000),
        nextEdges: edges(start: s * 5),
      )!;
      expect(p.inFrom, s * 5);
      expect(p.overlap, s * 5);
      // The song leaving may end loud: the plain equal power.
      expect(p.fastEntry, isFalse);
    });

    test('a song fading out by itself keeps its volume, the next comes in '
        'once it is 9 dB down', () {
      final p = plan(
        a,
        b,
        currentEdges: edges(end: s * 195, fadeDown: s * 190),
      )!;
      expect(p.outAt, s * 190);
      expect(p.end, s * 195);
      expect(p.leavingFades, isFalse);
      expect(p.fastEntry, isTrue);
    });

    test('a fade out by itself still overlaps no longer than set', () {
      final p = plan(
        a,
        b,
        settings: const MixSettings(
          crossfade: true,
          overlap: Duration(seconds: 3),
        ),
        currentEdges: edges(end: s * 195, fadeDown: s * 188),
      )!;
      expect(p.outAt, s * 188);
      expect(p.end, s * 191);
      expect(p.overlap, s * 3);
    });

    test('a fade out by itself overlaps a third of the next song at most', () {
      final p = plan(
        a,
        _song('b', albumId: 2, durationMs: 9000),
        currentEdges: edges(end: s * 196, fadeDown: s * 190),
      )!;
      expect(p.outAt, s * 190);
      expect(p.overlap, s * 3);
    });

    test('a drop too short to come in under is faded as any ending', () {
      final p = plan(
        a,
        b,
        currentEdges: edges(end: s * 195, fadeDown: s * 194),
      )!;
      expect(p.leavingFades, isTrue);
      expect(p.outAt, s * 189);
    });

    test('a drop early in the song is not its fade', () {
      final p = plan(
        a,
        b,
        length: s * 30,
        currentEdges: edges(end: s * 30, fadeDown: s * 5),
      )!;
      expect(p.leavingFades, isTrue);
      expect(p.outAt, s * 30 - TransitionPlanner.tailMargin - s * 6);
    });

    test('smart transitions off: edges are ignored', () {
      final p = plan(
        a,
        b,
        settings: const MixSettings(crossfade: true, smart: false),
        currentEdges: edges(end: s * 190, fadeDown: s * 185),
        nextEdges: edges(start: s * 3),
      );
      expect(p, plan(a, b));
      expect(p!.fastEntry, isFalse);
    });

    test('an album kept whole stays whole', () {
      expect(
        plan(
          _song('a', number: 1),
          _song('b', number: 2),
          currentEdges: edges(end: s * 190),
        ),
        isNull,
      );
    });
  });

  group('gainsAt', () {
    test('equal power without edges', () {
      const p = TransitionPlan(
        outAt: Duration(seconds: 10),
        end: Duration(seconds: 14),
        inFrom: Duration.zero,
      );
      final (out, into) = p.gainsAt(s * 12);
      expect(out, closeTo(math.sqrt1_2, 1e-12));
      expect(into, closeTo(math.sqrt1_2, 1e-12));
      expect(p.gainsAt(s * 10), (1.0, 0.0));
    });

    test('a fast entry is whole at 60 % of its ramp', () {
      const p = TransitionPlan(
        outAt: Duration(seconds: 10),
        end: Duration(seconds: 20),
        inFrom: Duration.zero,
        fastEntry: true,
      );
      expect(p.gainsAt(s * 16).$2, closeTo(1, 1e-12));
      expect(p.gainsAt(s * 13).$2, closeTo(math.sqrt1_2, 1e-12));
      // The song leaving still fades over the whole overlap.
      expect(p.gainsAt(s * 15).$1, closeTo(math.sqrt1_2, 1e-12));
    });

    test('a song fading by itself keeps its gain until the next is whole, '
        'then goes down to nothing at the end', () {
      const p = TransitionPlan(
        outAt: Duration(seconds: 10),
        end: Duration(seconds: 20),
        inFrom: Duration.zero,
        leavingFades: false,
        fastEntry: true,
      );
      for (final at in [10, 12, 16]) {
        expect(p.gainsAt(s * at).$1, 1);
      }
      expect(p.gainsAt(s * 16).$2, closeTo(1, 1e-12));
      expect(p.gainsAt(s * 18).$1, closeTo(math.sqrt1_2, 1e-12));
      expect(p.gainsAt(s * 18).$2, 1);
      expect(p.gainsAt(s * 20).$1, closeTo(0, 1e-12));
    });
  });

  test('progressAt runs from 0 at outAt to 1 at the end', () {
    const p = TransitionPlan(
      outAt: Duration(seconds: 10),
      end: Duration(seconds: 14),
      inFrom: Duration.zero,
    );
    expect(p.progressAt(s * 9), 0);
    expect(p.progressAt(s * 12), 0.5);
    expect(p.progressAt(s * 15), 1);
  });
}
