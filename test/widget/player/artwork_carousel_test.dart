import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/widgets/artwork_carousel.dart';

void main() {
  final tracks = [for (var i = 0; i < 5; i++) _track('t$i')];

  Future<List<int>> pumpCarousel(
    WidgetTester tester, {
    int currentIndex = 1,
    List<int>? changes,
    List<Track>? queue,
  }) async {
    changes ??= <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: ArtworkCarousel(
                queue: queue ?? tracks,
                currentIndex: currentIndex,
                onPageChanged: changes.add,
              ),
            ),
          ),
        ),
      ),
    );
    return changes;
  }

  testWidgets('renders a single BackdropFilter for the whole stage', (
    tester,
  ) async {
    await pumpCarousel(tester);
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('a swipe reports the new page only once it has settled', (
    tester,
  ) async {
    final changes = await pumpCarousel(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    // Past the half-page mark: the old onPageChanged would already fire here.
    await gesture.moveBy(const Offset(-150, 0));
    await tester.pump();
    expect(changes, isEmpty);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(changes, [2]);
  });

  testWidgets('a bloc-driven index change animates without echoing back', (
    tester,
  ) async {
    final changes = await pumpCarousel(tester, currentIndex: 1);

    await pumpCarousel(tester, currentIndex: 3, changes: changes);
    await tester.pumpAndSettle();

    final controller = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;
    expect(controller.page, 3);
    expect(changes, isEmpty);
  });

  PageController controllerOf(WidgetTester tester) =>
      tester.widget<PageView>(find.byType(PageView)).controller!;

  testWidgets('a skip animates through intermediate pages', (tester) async {
    final changes = await pumpCarousel(tester, currentIndex: 1);
    await pumpCarousel(tester, currentIndex: 2, changes: changes);

    await tester.pump(const Duration(milliseconds: 100));
    final midway = controllerOf(tester).page!;
    expect(midway, greaterThan(1));
    expect(midway, lessThan(2));

    await tester.pumpAndSettle();
    expect(controllerOf(tester).page, 2);
  });

  testWidgets('a tap during a skip animation does not cancel the skip', (
    tester,
  ) async {
    final changes = await pumpCarousel(tester, currentIndex: 1);
    await pumpCarousel(tester, currentIndex: 2, changes: changes);
    await tester.pump(const Duration(milliseconds: 40));

    await tester.tapAt(tester.getCenter(find.byType(PageView)));
    await tester.pumpAndSettle();

    expect(changes, isEmpty);
    expect(controllerOf(tester).page, 2);
  });

  testWidgets('a bloc update during a drag does not steal the gesture', (
    tester,
  ) async {
    final changes = await pumpCarousel(tester, currentIndex: 1);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();

    // The track ends while the finger is down.
    await pumpCarousel(tester, currentIndex: 2, changes: changes);
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();
    final followed = controllerOf(tester).page!;
    // 80 px dragged on 168 px pages: the finger still drives the scroll.
    expect(followed, closeTo(1 + 80 / 168, 0.05));

    // Released back where it started: realign with the playing track.
    await gesture.moveBy(const Offset(80, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
    expect(controllerOf(tester).page, 2);
  });

  testWidgets('a queue change jumps instead of sweeping', (tester) async {
    final changes = await pumpCarousel(tester, currentIndex: 3);
    final shuffled = tracks.reversed.toList();

    await pumpCarousel(
      tester,
      currentIndex: 0,
      changes: changes,
      queue: shuffled,
    );
    await tester.pump();

    expect(controllerOf(tester).page, 0);
    expect(changes, isEmpty);
  });

  testWidgets('a queue that grows lands on the right page', (tester) async {
    // Loading a track missing from the shown queue shows it alone first,
    // then the full queue arrives with the real index.
    final changes = await pumpCarousel(
      tester,
      currentIndex: 0,
      queue: [tracks[3]],
    );
    await pumpCarousel(tester, currentIndex: 3, changes: changes);
    await tester.pumpAndSettle();

    expect(controllerOf(tester).page, 3);
    expect(changes, isEmpty);
  });

  testWidgets('a queue change during a drag is not reported and jumps', (
    tester,
  ) async {
    final changes = await pumpCarousel(tester, currentIndex: 1);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();

    // The full queue arrives mid-drag: the current track is now at 4.
    final rotated = [...tracks.sublist(2), ...tracks.sublist(0, 2)];
    await pumpCarousel(
      tester,
      currentIndex: 4,
      changes: changes,
      queue: rotated,
    );
    await gesture.moveBy(const Offset(-110, 0));
    await gesture.up();

    // No page between the drag end and the jump may be swept through.
    final pages = <double>[];
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      pages.add(controllerOf(tester).page!);
    }
    await tester.pumpAndSettle();

    expect(changes, isEmpty);
    expect(controllerOf(tester).page, 4);
    expect(pages.where((p) => p > 2.5 && p < 3.5), isEmpty);
  });

  testWidgets('a swipe the bloc ignores snaps back', (tester) async {
    final changes = await pumpCarousel(tester, currentIndex: 1);

    await tester.drag(find.byType(PageView), const Offset(-150, 0));
    await tester.pumpAndSettle();
    expect(changes, [2]);

    // The bloc never confirms: after the timeout the stage realigns.
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    expect(controllerOf(tester).page, 1);
  });

  testWidgets('handles single, empty and broken-artwork queues', (
    tester,
  ) async {
    await pumpCarousel(tester, currentIndex: 0, queue: [tracks.first]);
    expect(tester.takeException(), isNull);

    await pumpCarousel(tester, currentIndex: 0, queue: const []);
    expect(tester.takeException(), isNull);

    final broken = _track('x')..artworkPath = '/does/not/exist.jpg';
    await pumpCarousel(tester, currentIndex: 0, queue: [broken]);
    // The failing file read is real I/O, outside the fake clock.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byIcon(CupertinoIcons.music_note), findsOneWidget);
  });
}

Track _track(String id) => Track(
  id: id,
  title: 'Title $id',
  artist: 'Artist',
  artistId: 1,
  album: 'Album',
  albumId: 1,
  path: '/music/$id.mp3',
  uri: 'content://$id',
  size: 1,
  durationMs: 180000,
  fileName: '$id.mp3',
);
