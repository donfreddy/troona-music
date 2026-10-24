import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/player/presentation/widgets/track_title_switcher.dart';

import '../../helpers/fake_player.dart';

final _tracks = [
  for (final id in 'abcde'.split('')) testTrack(id, durationMs: 180000),
];

void main() {
  group('isNextTrack', () {
    test('follows the queue order', () {
      expect(isNextTrack(1, 2, 5), isTrue);
      expect(isNextTrack(2, 1, 5), isFalse);
    });

    test('last to first is a next, first to last a previous', () {
      expect(isNextTrack(4, 0, 5), isTrue);
      expect(isNextTrack(0, 4, 5), isFalse);
    });

    test('with two tracks, plain order wins', () {
      expect(isNextTrack(1, 0, 2), isFalse);
      expect(isNextTrack(0, 1, 2), isTrue);
    });

    test('unknown positions count as a next', () {
      expect(isNextTrack(null, 3, 5), isTrue);
      expect(isNextTrack(3, null, 5), isTrue);
    });
  });

  Future<void> show(WidgetTester tester, int index) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: TrackTitleSwitcher(
              track: _tracks[index],
              index: index,
              queueLength: _tracks.length,
            ),
          ),
        ),
      ),
    ),
  );

  double top(WidgetTester tester, String id) =>
      tester.getTopLeft(find.text('Title $id')).dy;

  List<double> tops(WidgetTester tester, String id) => [
    for (final e in find.text('Title $id').evaluate())
      tester.getTopLeft(find.byElementPredicate((x) => x == e)).dy,
  ];

  Finder mask() => find.descendant(
    of: find.byType(TrackTitleSwitcher),
    matching: find.byType(ShaderMask),
  );

  late double rest;

  Future<void> start(WidgetTester tester, int index) async {
    await show(tester, index);
    rest = top(tester, _tracks[index].id);
  }

  testWidgets('a next track rises: old out the top, new from below', (
    tester,
  ) async {
    await start(tester, 1);

    await show(tester, 2);
    await tester.pump(const Duration(milliseconds: 100));

    expect(top(tester, 'b'), lessThan(rest));
    expect(top(tester, 'c'), greaterThan(rest));
  });

  testWidgets('a previous track falls: old out the bottom, new from above', (
    tester,
  ) async {
    await start(tester, 2);

    await show(tester, 1);
    await tester.pump(const Duration(milliseconds: 100));

    expect(top(tester, 'c'), greaterThan(rest));
    expect(top(tester, 'b'), lessThan(rest));
  });

  testWidgets('from the last track to the first, titles rise', (tester) async {
    await start(tester, 4);

    await show(tester, 0);
    await tester.pump(const Duration(milliseconds: 100));

    expect(top(tester, 'e'), lessThan(rest));
    expect(top(tester, 'a'), greaterThan(rest));
  });

  testWidgets('a title leaving upwards keeps going up after a previous', (
    tester,
  ) async {
    await start(tester, 0);

    await show(tester, 1); // next: "a" leaves through the top
    await tester.pump(const Duration(milliseconds: 60));
    await show(tester, 0); // previous: "b" leaves through the bottom
    await tester.pump(const Duration(milliseconds: 60));

    // The leaving "a" and the arriving "a" are both above.
    expect(tops(tester, 'a'), everyElement(lessThan(rest)));
    expect(top(tester, 'b'), greaterThan(rest));
  });

  testWidgets('settles back in place', (tester) async {
    await start(tester, 1);

    await show(tester, 2);
    await tester.pumpAndSettle();

    expect(find.text('Title b'), findsNothing);
    expect(top(tester, 'c'), rest);
  });

  testWidgets('edges fade only while titles move', (tester) async {
    await start(tester, 1);
    expect(mask(), findsNothing);

    await show(tester, 2);
    await tester.pump(const Duration(milliseconds: 100));
    expect(mask(), findsOneWidget);

    await tester.pumpAndSettle();
    expect(mask(), findsNothing);
  });

  testWidgets('the same track again changes nothing', (tester) async {
    await start(tester, 1);

    await show(tester, 1);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Title b'), findsOneWidget);
    expect(top(tester, 'b'), rest);
    expect(mask(), findsNothing);
  });
}
