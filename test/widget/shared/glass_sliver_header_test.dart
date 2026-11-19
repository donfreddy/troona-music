import 'dart:math' as math;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/components/glass_filter.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';
import 'package:troona/shared/widgets/glass_sliver_header.dart';

import '../../helpers/roboto.dart';

void main() {
  setUpAll(loadRoboto);

  const statusBar = 24.0;
  const longTitle = 'Bibliothèque musicale partagée';
  final actionKey = UniqueKey();
  final firstRowKey = UniqueKey();

  /// Scrolls started by code (not by a drag) since a page was pumped.
  var scrollStarts = 0;

  Future<ScrollController> pump(
    WidgetTester tester,
    GlassSliverHeader header, {
    double textScale = 1,
    GlassQuality quality = GlassQuality.high,
    int rows = 40,
  }) async {
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = const Size(360, 640) * 3
      ..padding = const FakeViewPadding(top: statusBar * 3);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: robotoTheme(AppTheme.withGlass(quality)),
        home: Scaffold(
          body: NotificationListener<ScrollStartNotification>(
            onNotification: (n) {
              // Started by code (a snap), not by a finger.
              if (n.dragDetails == null) scrollStarts++;
              return false;
            },
            child: CustomScrollView(
              controller: controller,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                header,
                SliverList.builder(
                  itemCount: rows,
                  // Tappable, like real rows: a finger down is not a drag
                  // until it moves.
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () {},
                    child: SizedBox(
                      key: i == 0 ? firstRowKey : null,
                      height: 56,
                      child: Text('Row $i'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    scrollStarts = 0;
    return controller;
  }

  GlassSliverHeader largeTitle({String title = 'Library'}) =>
      GlassSliverHeader.largeTitle(
        title: title,
        actions: [
          GlassIconButton(
            key: actionKey,
            icon: Icons.refresh,
            tooltip: 'Refresh',
            onTap: () {},
          ),
        ],
      );

  BackdropFilter backdrop(WidgetTester tester) =>
      tester.widget<BackdropFilter>(find.byType(BackdropFilter));

  /// The compact title, in the navigation row.
  Finder compactTitle(String title) => find.descendant(
    of: find.byType(NavigationToolbar),
    matching: find.text(title),
  );

  /// The large title, below the navigation row.
  Finder largeTitleText(String title) =>
      find.descendant(of: find.byType(FittedBox), matching: find.text(title));

  double compactTitleOpacity(WidgetTester tester, String title) => tester
      .widget<Opacity>(
        find
            .ancestor(of: compactTitle(title), matching: find.byType(Opacity))
            .first,
      )
      .opacity;

  Future<void> scrollTo(
    WidgetTester tester,
    ScrollController controller,
    double offset,
  ) async {
    controller.jumpTo(offset);
    await tester.pump();
  }

  testWidgets('expanded at rest: no blur, no compact title, no glass', (
    tester,
  ) async {
    await pump(tester, largeTitle());
    expect(backdrop(tester).enabled, isFalse);
    expect(compactTitleOpacity(tester, 'Library'), 0);
  });

  testWidgets('the blur comes on, at one sigma, once content passes under '
      'the collapsed bar, which takes the compact title', (tester) async {
    final controller = await pump(tester, largeTitle());
    final glass = GlassTheme.header(tester.element(find.byType(Scaffold)));
    // Exposed: a light cover under the title cannot wash it out.
    expect(glass.exposure, lessThan(1));
    final expected = GlassFilter.of(
      glass.blurSigma,
      saturation: glass.saturation,
      exposure: glass.exposure,
    );

    // Collapsing: only the page background is behind the header.
    await scrollTo(tester, controller, GlassSliverHeader.largeTitleHeight / 2);
    expect(backdrop(tester).enabled, isFalse);

    await scrollTo(tester, controller, GlassSliverHeader.largeTitleHeight);
    expect(backdrop(tester).enabled, isTrue);
    expect(backdrop(tester).filter, expected);

    await scrollTo(tester, controller, 400);
    expect(backdrop(tester).filter, expected);
    expect(compactTitleOpacity(tester, 'Library'), 1);
  });

  testWidgets('collapsed, the content scrolls under the glass bar', (
    tester,
  ) async {
    final controller = await pump(tester, largeTitle());
    final barBottom = statusBar + GlassSliverHeader.navBarHeight;

    // Expanded: the list starts below the large title.
    expect(
      tester.getTopLeft(find.byKey(firstRowKey)).dy,
      barBottom + GlassSliverHeader.largeTitleHeight,
    );

    await scrollTo(tester, controller, GlassSliverHeader.largeTitleHeight + 20);
    final row = tester.getRect(find.byKey(firstRowKey));
    expect(row.top, lessThan(barBottom));
    expect(row.bottom, greaterThan(barBottom - 20));
  });

  testWidgets('balanced glass keeps the header\'s blur, at full strength', (
    tester,
  ) async {
    final controller = await pump(
      tester,
      largeTitle(),
      quality: GlassQuality.low,
    );
    await scrollTo(tester, controller, 400);
    final blur = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
    expect(blur.enabled, isTrue);
    expect(blur.filter.toString(), contains('blur(30.0, 30.0'));
  });

  group('pages crossing', () {
    final navigator = GlobalKey<NavigatorState>();
    late ScrollController first;
    late ScrollController second;

    Widget page(String title, ScrollController controller) => Scaffold(
      body: CustomScrollView(
        controller: controller,
        slivers: [
          GlassSliverHeader.largeTitle(title: title),
          SliverList.builder(
            itemCount: 40,
            itemBuilder: (_, i) => SizedBox(height: 56, child: Text('$i')),
          ),
        ],
      ),
    );

    /// The blurs drawing, by the page each belongs to. A page covered by
    /// another is offstage: not painted, so not counted.
    List<String> blurring(WidgetTester tester) => [
      for (final element in find.byType(BackdropFilter).evaluate())
        if ((element.widget as BackdropFilter).enabled)
          element
                      .findAncestorWidgetOfExactType<CustomScrollView>()!
                      .controller ==
                  first
              ? 'A'
              : 'B',
    ];

    Future<List<List<String>>> record(WidgetTester tester) async {
      final frames = <List<String>>[];
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        frames.add(blurring(tester));
      }
      return frames;
    }

    /// Pumps A, scrolled to [aScroll], and pushes B over it, recording
    /// the blurs of each frame of the push.
    Future<List<List<String>>> openB(
      WidgetTester tester,
      GlassQuality quality, {
      double aScroll = 400,
    }) async {
      tester.view
        ..devicePixelRatio = 3
        ..physicalSize = const Size(360, 640) * 3;
      addTearDown(tester.view.reset);
      first = ScrollController();
      second = ScrollController();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          // The app's theme: Cupertino transitions, with the back swipe.
          theme: robotoTheme(AppTheme.withGlass(quality)),
          home: page('A', first),
        ),
      );
      first.jumpTo(aScroll);
      await tester.pumpAndSettle();
      unawaited(
        navigator.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => page('B', second)),
        ),
      );
      final frames = await record(tester);
      await tester.pumpAndSettle();
      second.jumpTo(400);
      await tester.pump();
      expect(blurring(tester), ['B']);
      return frames;
    }

    testWidgets('a push leaves the page below as it was: the page pushed '
        'opens expanded, so it never blurs as well', (tester) async {
      final frames = await openB(tester, GlassQuality.low);
      expect(frames, everyElement(['A']));
    });

    testWidgets('balanced glass: popping back to a collapsed page, one blur, '
        'the one of the page coming back, from the start', (tester) async {
      await openB(tester, GlassQuality.low);
      navigator.currentState!.pop();
      final frames = await record(tester);
      expect(frames, everyElement(['A']));
      await tester.pumpAndSettle();
      expect(blurring(tester), ['A']);
    });

    testWidgets('full glass is left as it was: both blur while they cross', (
      tester,
    ) async {
      await openB(tester, GlassQuality.high);
      navigator.currentState!.pop();
      final frames = await record(tester);
      expect(frames, contains(unorderedEquals(['A', 'B'])));
    });

    testWidgets('popping back to a page at its top, the page leaving keeps '
        'its glass: nothing else blurs', (tester) async {
      await openB(tester, GlassQuality.low, aScroll: 0);
      navigator.currentState!.pop();
      final frames = await record(tester);
      expect(frames.first, ['B']);
      for (final blurs in frames) {
        expect(blurs, anyOf(isEmpty, ['B']), reason: '$blurs');
      }
    });

    Future<TestGesture> swipe(WidgetTester tester) async {
      final gesture = await tester.startGesture(const Offset(4, 320));
      for (var i = 0; i < 6; i++) {
        await gesture.moveBy(const Offset(30, 0));
        await tester.pump(const Duration(milliseconds: 16));
        // The first step starts the gesture before the page below is on
        // screen: a frame with no blur, never two.
        expect(
          blurring(tester),
          i == 0 ? anyOf(isEmpty, ['A']) : ['A'],
          reason: 'drag $i',
        );
      }
      return gesture;
    }

    testWidgets('balanced glass: a back swipe hands the blur to the page '
        'below as it starts, and keeps it there when it goes through', (
      tester,
    ) async {
      await openB(tester, GlassQuality.low);
      final gesture = await swipe(tester);
      await gesture.moveBy(const Offset(150, 0));
      await gesture.up();
      final frames = await record(tester);
      expect(frames, everyElement(['A']));
      await tester.pumpAndSettle();
      expect(blurring(tester), ['A']);
    });

    testWidgets('balanced glass: a back swipe called off hands the blur '
        'back to the page on top', (tester) async {
      await openB(tester, GlassQuality.low);
      final gesture = await swipe(tester);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(blurring(tester), ['B']);
    });
  });

  testWidgets('glass off: no BackdropFilter at all', (tester) async {
    final controller = await pump(
      tester,
      largeTitle(),
      quality: GlassQuality.off,
    );
    await scrollTo(tester, controller, 400);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('360 dp, text x$scale: a long title stays whole and the '
        'compact one clears the actions', (tester) async {
      final controller = await pump(
        tester,
        largeTitle(title: longTitle),
        textScale: scale,
      );
      expect(tester.takeException(), isNull);

      // The large title fits its line: scaled down, never cut.
      final large = largeTitleText(longTitle);
      expect(tester.getRect(large).right, lessThanOrEqualTo(360 - 16 + 0.5));

      await scrollTo(tester, controller, 600);
      expect(tester.takeException(), isNull);
      final compact = compactTitle(longTitle);
      final paragraph = tester.renderObject<RenderParagraph>(compact);
      expect(paragraph.maxLines, 1);
      final action = tester.getRect(find.byKey(actionKey));
      expect(
        tester.getRect(compact).right,
        lessThanOrEqualTo(action.left),
        reason: 'compact title over the actions',
      );
    });
  }

  testWidgets('the large title grows its room with the font size', (
    tester,
  ) async {
    await pump(tester, largeTitle(), textScale: 2);
    expect(
      tester.getTopLeft(find.byKey(firstRowKey)).dy,
      statusBar +
          GlassSliverHeader.navBarHeight +
          GlassSliverHeader.largeTitleHeight +
          41, // one more large-title line
    );
  });

  testWidgets('faded expanded content takes no tap', (tester) async {
    var taps = 0;
    final controller = await pump(
      tester,
      GlassSliverHeader(
        title: 'Album',
        expandedHeight: 200,
        expanded: Align(
          alignment: Alignment.bottomCenter,
          child: TextButton(onPressed: () => taps++, child: const Text('Play')),
        ),
      ),
    );
    await tester.tap(find.text('Play'));
    expect(taps, 1);

    // Collapsed: faded out.
    await scrollTo(tester, controller, 200);
    final ignoring = tester
        .widgetList<IgnorePointer>(
          find.ancestor(
            of: find.text('Play'),
            matching: find.byType(IgnorePointer),
          ),
        )
        .any((w) => w.ignoring);
    expect(ignoring, isTrue);
  });

  testWidgets('a cover mostly scrolled out of sight does not fly back', (
    tester,
  ) async {
    final controller = await pump(
      tester,
      const GlassSliverHeader(
        title: 'Album',
        expandedHeight: 200,
        expanded: Hero(tag: 'cover', child: SizedBox(width: 80, height: 80)),
      ),
    );
    bool heroOn() => tester
        .widgetList<HeroMode>(
          find.ancestor(of: find.byType(Hero), matching: find.byType(HeroMode)),
        )
        .every((m) => m.enabled);
    expect(heroOn(), isTrue);

    await scrollTo(tester, controller, 60);
    expect(heroOn(), isTrue, reason: 'mostly in sight');

    await scrollTo(tester, controller, 140);
    expect(heroOn(), isFalse, reason: 'mostly faded');

    await scrollTo(tester, controller, 200);
    expect(heroOn(), isFalse);
  });

  testWidgets('a hero fades with the collapse, a large title sooner', (
    tester,
  ) async {
    double fadeOf(Finder text) => tester
        .widget<Opacity>(
          find.ancestor(of: text, matching: find.byType(Opacity)).first,
        )
        .opacity;

    // Half collapsed: the hero's buttons still half there, no empty band.
    final hero = await pump(
      tester,
      const GlassSliverHeader(
        title: 'Album',
        expandedHeight: 200,
        expanded: Align(alignment: Alignment.bottomCenter, child: Text('Play')),
      ),
    );
    await scrollTo(tester, hero, 100);
    expect(fadeOf(find.text('Play')), closeTo(.5, .01));

    final titled = await pump(tester, largeTitle());
    await scrollTo(tester, titled, GlassSliverHeader.largeTitleHeight / 2);
    expect(fadeOf(largeTitleText('Library')), closeTo(1 - .5 * 1.6, .01));
  });

  for (final large in [false, true]) {
    testWidgets('${large ? 'a large title' : 'a hero'}: the compact title '
        'comes in only once the expanded one is nearly gone', (tester) async {
      double fadeOf(Finder text) => tester
          .widget<Opacity>(
            find.ancestor(of: text, matching: find.byType(Opacity)).first,
          )
          .opacity;
      final controller = await pump(
        tester,
        large
            ? largeTitle(title: 'Khaid')
            : const GlassSliverHeader(
                title: 'Khaid',
                expandedHeight: 200,
                expanded: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text('Khaid', key: ValueKey('big')),
                ),
              ),
      );
      final big = large
          ? largeTitleText('Khaid')
          : find.byKey(const ValueKey('big'));
      final range = large ? GlassSliverHeader.largeTitleHeight : 200.0;

      for (var step = 0; step <= 20; step++) {
        await scrollTo(tester, controller, range * step / 20);
        final compact = compactTitleOpacity(tester, 'Khaid');
        final expanded = big.evaluate().isEmpty ? 0.0 : fadeOf(big);
        expect(
          math.min(compact, expanded),
          lessThanOrEqualTo(GlassSliverHeader.titleHandover + 1e-9),
          reason: 'both names at once, at ${step * 5} %',
        );
      }
      expect(compactTitleOpacity(tester, 'Khaid'), 1, reason: 'collapsed');

      await scrollTo(tester, controller, range * 0.1);
      expect(compactTitleOpacity(tester, 'Khaid'), 0, reason: 'early');

      // Not late either: in by the time the expanded title is gone.
      await scrollTo(tester, controller, range * (large ? 0.75 : 0.9));
      expect(compactTitleOpacity(tester, 'Khaid'), greaterThan(0.3));
    });
  }

  /// An album-like hero: the title in the middle, 120 px of buttons below.
  const markedHero = GlassSliverHeader(
    title: 'Album',
    expandedHeight: 240,
    expanded: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GlassHeaderTitle(
          child: SizedBox(
            key: ValueKey('big'),
            height: 30,
            child: Text('Album'),
          ),
        ),
        SizedBox(height: 120),
      ],
    ),
  );

  testWidgets('a marked title: the compact one comes in as it goes under '
      'the bar, not when the hero below it has scrolled away', (tester) async {
    final controller = await pump(tester, markedHero);
    final bar = statusBar + GlassSliverHeader.navBarHeight;
    final big = find.byKey(const ValueKey('big'));
    // The first scroll frame measures the mark as last laid out.
    await scrollTo(tester, controller, 1);
    expect(compactTitleOpacity(tester, 'Album'), 0);

    // Its top reaches the bar after 90 px, its bottom after 120.
    await scrollTo(tester, controller, 90);
    expect(tester.getRect(big).top, closeTo(bar, 0.01));
    expect(compactTitleOpacity(tester, 'Album'), 0, reason: 'still whole');

    await scrollTo(tester, controller, 105);
    expect(compactTitleOpacity(tester, 'Album'), 0, reason: 'half under');
    await scrollTo(tester, controller, 112.5);
    expect(compactTitleOpacity(tester, 'Album'), closeTo(0.5, 0.01));

    // Hidden: the bar has the title, half of the hero still to go. By
    // collapse alone it would not have started (0.8 of 240 is 192).
    await scrollTo(tester, controller, 120);
    expect(tester.getRect(big).bottom, closeTo(bar, 0.01));
    expect(compactTitleOpacity(tester, 'Album'), 1);
    await scrollTo(tester, controller, 240);
    expect(compactTitleOpacity(tester, 'Album'), 1);

    await scrollTo(tester, controller, 0);
    expect(compactTitleOpacity(tester, 'Album'), 0);
  });

  testWidgets('a marked title the content cannot take under the bar stays, '
      'with no compact one', (tester) async {
    // 7 rows: the page scrolls less than the 120 px that hide the title.
    final controller = await pump(tester, markedHero, rows: 7);
    final end = controller.position.maxScrollExtent;
    expect(end, inExclusiveRange(0, 120));
    await scrollTo(tester, controller, end);
    expect(compactTitleOpacity(tester, 'Album'), 0);

    // Pulled past the end (a short playlist dragged up): the title keeps
    // its strength while it is in sight...
    final big = find.byKey(const ValueKey('big'));
    double bigOpacity() => tester
        .widget<Opacity>(
          find.ancestor(of: big, matching: find.byType(Opacity)).first,
        )
        .opacity;
    final atRest = bigOpacity();
    await scrollTo(tester, controller, end + 30);
    expect(bigOpacity(), atRest, reason: 'no dimming under the finger');
    expect(compactTitleOpacity(tester, 'Album'), 0);

    // ...and once it is under the bar, the bar has it.
    await scrollTo(tester, controller, 121);
    expect(
      tester.getRect(big).bottom,
      lessThanOrEqualTo(statusBar + GlassSliverHeader.navBarHeight),
      reason: 'the pull took the title under the bar',
    );
    expect(compactTitleOpacity(tester, 'Album'), 1);

    await tester.pumpAndSettle();
    expect(controller.offset, closeTo(end, 0.5), reason: 'sprung back');
    expect(compactTitleOpacity(tester, 'Album'), 0, reason: 'back at rest');
  });

  test('an unmarked title on short content: none at rest, in when pulled '
      'past the handover', () {
    expect(GlassSliverHeader.titleOpacityAt(0.3, reach: 0.3), 0);
    expect(
      GlassSliverHeader.titleOpacityAt(0.9, reach: 0.3),
      closeTo(0.5, 1e-9),
    );
    expect(GlassSliverHeader.titleOpacityAt(1, reach: 0.3), 1);
  });

  const shortHero = GlassSliverHeader(
    title: 'Album',
    expandedHeight: 200,
    expanded: Align(alignment: Alignment.bottomLeft, child: Text('Big')),
  );

  testWidgets('content too short to collapse the header fully: the compact '
      'title is whole at the end of the scroll', (tester) async {
    // 10 rows: the page scrolls 188 of the header's 200.
    final controller = await pump(tester, shortHero, rows: 10);
    final end = controller.position.maxScrollExtent;
    expect(end, inExclusiveRange(160, 200));
    await scrollTo(tester, controller, end);
    expect(compactTitleOpacity(tester, 'Album'), 1);
  });

  testWidgets('a page that barely scrolls keeps its expanded title, no '
      'compact one', (tester) async {
    final controller = await pump(tester, shortHero, rows: 7);
    await scrollTo(tester, controller, controller.position.maxScrollExtent);
    expect(compactTitleOpacity(tester, 'Album'), 0);
  });

  testWidgets('a header without a navigation row takes its glass once '
      'content is under it', (tester) async {
    final controller = await pump(
      tester,
      const GlassSliverHeader(
        pinnedBottom: SizedBox(height: 40, child: Text('Search field')),
        pinnedBottomHeight: 56,
      ),
    );
    expect(backdrop(tester).enabled, isFalse);
    expect(
      tester.getTopLeft(find.byKey(firstRowKey)).dy,
      statusBar + 56,
      reason: 'no navigation row above the field',
    );
    await scrollTo(tester, controller, 30);
    expect(backdrop(tester).enabled, isTrue);
  });

  testWidgets('stretch: overscroll grows the background with the header', (
    tester,
  ) async {
    final bg = UniqueKey();
    final controller = await pump(
      tester,
      GlassSliverHeader(
        title: 'Artist',
        expandedHeight: 300,
        stretch: true,
        background: ColoredBox(key: bg, color: Colors.red),
        expanded: const SizedBox(),
      ),
    );
    final rest = tester.getSize(find.byKey(bg)).height;
    expect(rest, statusBar + GlassSliverHeader.navBarHeight + 300);

    controller.jumpTo(-60);
    await tester.pump();
    expect(tester.getSize(find.byKey(bg)).height, greaterThan(rest));
    expect(tester.getTopLeft(find.byKey(bg)).dy, 0);

    // Collapsing: its bottom follows the header's edge, never cut short.
    controller.jumpTo(100);
    await tester.pump();
    expect(tester.getBottomLeft(find.byKey(bg)).dy, rest - 100);
  });

  for (final (drag, end) in [(40.0, 'expanded'), (75.0, 'collapsed')]) {
    testWidgets('a large title left halfway ends $end', (tester) async {
      final controller = await pump(tester, largeTitle());
      const range = GlassSliverHeader.largeTitleHeight;
      final gesture = await tester.startGesture(const Offset(180, 400));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(Offset(0, -drag / 10));
        await tester.pump(const Duration(milliseconds: 16));
      }
      // Held still before release: no fling.
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.offset, inExclusiveRange(0, range));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(controller.offset, end == 'expanded' ? 0 : range);
    });
  }

  testWidgets('an album hero does not snap', (tester) async {
    final controller = await pump(
      tester,
      const GlassSliverHeader(
        title: 'Album',
        expandedHeight: 300,
        expanded: SizedBox(),
      ),
    );
    final gesture = await tester.startGesture(const Offset(180, 500));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, -12));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 300));
    final before = controller.offset;
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.offset, before);
  });

  testWidgets('a pushed page: the back button at the start, the compact '
      'title between it and the actions', (tester) async {
    final back = UniqueKey();
    final controller = await pump(
      tester,
      GlassSliverHeader(
        // Centres itself, like AppBackButton.
        leading: Center(key: back, child: const SizedBox.square(dimension: 45)),
        title: 'Glass Horizons',
        actions: [
          GlassIconButton(
            key: actionKey,
            icon: Icons.more_vert,
            tooltip: 'More',
            onTap: () {},
          ),
        ],
        expandedHeight: 300,
        expanded: const SizedBox(),
      ),
    );
    await scrollTo(tester, controller, 400);
    final backRect = tester.getRect(find.byKey(back));
    expect(backRect.left, 8);
    expect(backRect.width, 45);
    final title = tester.getRect(compactTitle('Glass Horizons'));
    expect(title.width, greaterThan(100));
    expect(title.left, greaterThanOrEqualTo(backRect.right));
    expect(
      title.right,
      lessThanOrEqualTo(tester.getRect(find.byKey(actionKey)).left),
    );
  });

  testWidgets('a finger that stops a scroll halfway is not snapped under; '
      'its release snaps', (tester) async {
    final controller = await pump(tester, largeTitle());
    const range = GlassSliverHeader.largeTitleHeight;
    unawaited(
      controller.animateTo(
        range,
        duration: const Duration(seconds: 1),
        curve: Curves.linear,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    // The finger stops it (a hold, which ends the scroll).
    final startsBefore = scrollStarts;
    final gesture = await tester.startGesture(const Offset(180, 400));
    await tester.pump();
    final held = controller.offset;
    expect(held, inExclusiveRange(range / 2, range));
    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.offset, held);
    expect(
      scrollStarts,
      startsBefore,
      reason: 'a snap started under the finger',
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.offset, range);
  });

  testWidgets('content too short to collapse the header is never snapped '
      'back', (tester) async {
    // 640 - 24 - 44 - 86 = 486 dp of room: 10 rows of 56 leave 74 dp of
    // scroll, less than the 86 the collapse takes.
    final controller = await pump(tester, largeTitle(), rows: 10);
    final position = controller.position;
    expect(
      position.maxScrollExtent,
      lessThan(GlassSliverHeader.largeTitleHeight),
    );
    final gesture = await tester.startGesture(const Offset(180, 400));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, -8));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 300));
    final before = controller.offset;
    expect(before, greaterThan(0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.offset, closeTo(before, 0.5));
  });

  testWidgets('collapsed, the glass fades out below the bar instead of '
      'ending on a line', (tester) async {
    final controller = await pump(tester, largeTitle());
    await scrollTo(tester, controller, 400);
    const barBottom = statusBar + GlassSliverHeader.navBarHeight;

    // The blur stops at the bar's edge; the tint carries on below it and
    // fades out.
    expect(tester.getRect(find.byType(BackdropFilter)).bottom, barBottom);
    final edge = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .firstWhere((box) {
          final d = box.decoration;
          return d is BoxDecoration && d.gradient != null;
        });
    final edgeRect = tester.getRect(find.byWidget(edge));
    expect(edgeRect.top, barBottom);
    expect(edgeRect.bottom, barBottom + GlassSliverHeader.softEdge);
    final colors = (edge.decoration as BoxDecoration).gradient!.colors;
    expect(colors.first.a, greaterThan(0));
    expect(colors.last.a, 0);

    // Content under the soft edge still takes taps.
    expect(
      tester
          .hitTestOnBinding(Offset(180, barBottom + 10))
          .path
          .any((entry) => entry.target is RenderParagraph),
      isTrue,
    );

    // No hairline: no full-width box draws a border.
    final borders = [
      for (final element in find.byType(DecoratedBox).evaluate())
        if ((element.widget as DecoratedBox).decoration
            case BoxDecoration(:final border?)
            when border.bottom.width > 0 &&
                tester.getRect(find.byWidget(element.widget)).width == 360)
          element,
    ];
    expect(borders, isEmpty);
  });
}
