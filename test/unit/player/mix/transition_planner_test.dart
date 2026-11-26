import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/mix_settings.dart';
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
  }) => TransitionPlanner.plan(
    current: current,
    length: length,
    next: next,
    settings: settings,
  );

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
