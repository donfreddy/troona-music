import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/widgets/artwork_carousel.dart';
import 'package:troona/features/player/presentation/widgets/now_playing_hero.dart';

const _miniArt = ValueKey('mini-art');

void main() {
  final tracks = [
    for (var i = 0; i < 3; i++)
      _track('t$i')..artworkPath = '/does/not/exist/$i.jpg',
  ];

  void pushStage(NavigatorState navigator, {bool enableHeroes = true}) {
    navigator.push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: ArtworkCarousel(
                queue: tracks,
                currentIndex: 1,
                onPageChanged: (_) {},
                enableHeroes: enableHeroes,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<NavigatorState> pumpMini(
    WidgetTester tester, {
    bool enableHeroes = true,
  }) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            // Same declaration order as the real mini player row.
            child: SizedBox(
              width: 360,
              height: 64,
              child: Stack(
                children: [
                  const Hero(
                    tag: NowPlayingHero.surfaceTag,
                    flightShuttleBuilder: NowPlayingHero.surfaceShuttle,
                    child: SizedBox.expand(),
                  ),
                  Positioned(
                    left: 12,
                    top: 11,
                    width: 42,
                    height: 42,
                    child: Hero(
                      tag: NowPlayingHero.artworkTag,
                      flightShuttleBuilder: NowPlayingHero.artworkShuttle,
                      child: Image.file(
                        File('/does/not/exist/mini.jpg'),
                        key: _miniArt,
                        errorBuilder: (_, _, _) => const SizedBox.expand(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    pushStage(navigator.currentState!, enableHeroes: enableHeroes);
    return navigator.currentState!;
  }

  bool isSurfaceShuttle(Widget w) =>
      w is DecoratedBox &&
      w.decoration is BoxDecoration &&
      ((w.decoration as BoxDecoration).color?.toARGB32() ?? 0) & 0xFFFFFF ==
          0x07090E;

  /// Tree (and paint) order of the two shuttles in the overlay.
  (int surface, int artwork) shuttleOrder(WidgetTester tester) {
    final elements = tester.allElements.toList();
    final surface = elements.indexWhere((e) => isSurfaceShuttle(e.widget));
    // Last match: the source hero keeps an offstage copy of its child.
    final artwork = elements.lastIndexWhere((e) => e.widget.key == _miniArt);
    return (surface, artwork);
  }

  testWidgets('the cover flies above the surface when opening', (tester) async {
    await pumpMini(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final (surface, artwork) = shuttleOrder(tester);
    expect(surface, isNot(-1));
    expect(artwork, greaterThan(surface));
    await tester.pumpAndSettle();
  });

  testWidgets('the cover flies above the surface when dismissing', (
    tester,
  ) async {
    final navigator = await pumpMini(tester);
    await tester.pumpAndSettle();

    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final (surface, artwork) = shuttleOrder(tester);
    expect(surface, isNot(-1));
    expect(artwork, greaterThan(surface));
    await tester.pumpAndSettle();
  });

  testWidgets('the mini row hides while covered and lands with the shuttle', (
    tester,
  ) async {
    final route = AnimationController(
      vsync: tester,
      duration: const Duration(milliseconds: 500),
    );
    final cover = NowPlayingHero.curveLikeFlight(route);
    addTearDown(() {
      cover.dispose();
      route.dispose();
    });
    double opacity() => NowPlayingHero.miniRowOpacity(cover);

    expect(opacity(), 1, reason: 'not covered');

    route.forward();
    route.value = 0.5;
    expect(opacity(), 0, reason: 'mid-flight on open');

    route.value = 1;
    expect(opacity(), 0, reason: 'fully covered');

    route.reverse();
    route.value = 0.5;
    expect(opacity(), 0, reason: 'mid-flight on dismiss');
    route.value = 0.1;
    expect(opacity(), allOf(greaterThan(0), lessThan(1)), reason: 'landing');
    route.value = 0;
    expect(opacity(), 1, reason: 'landed');
  });

  testWidgets('a dismiss interrupted by a reopen still morphs into the ring', (
    tester,
  ) async {
    final navigator = await pumpMini(tester);
    await tester.pumpAndSettle();

    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    // Reopen mid-dismiss: Flutter diverts the running flights.
    pushStage(navigator);
    await tester.pump();

    double surfaceAlpha() {
      final box = tester.widget<DecoratedBox>(
        find.byWidgetPredicate(isSurfaceShuttle),
      );
      return (box.decoration as BoxDecoration).color!.a;
    }

    final alphas = <double>[];
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 30));
      if (find.byWidgetPredicate(isSurfaceShuttle).evaluate().isEmpty) break;
      alphas.add(surfaceAlpha());
    }

    // The shuttle grows back towards the ring: it must stay opaque, not fade
    // out with the first flight's (reversing) animation.
    expect(alphas, isNotEmpty);
    expect(alphas.last, closeTo(0.8, 0.01));
    await tester.pumpAndSettle();
  });

  testWidgets('nothing flies when the stage disables its heroes', (
    tester,
  ) async {
    await pumpMini(tester, enableHeroes: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(shuttleOrder(tester).$1, -1);
    await tester.pumpAndSettle();
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
