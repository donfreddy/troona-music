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
  tearDown(() => GlassTheme.overrideQuality(null));

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
    GlassTheme.overrideQuality(quality);
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
        theme: robotoTheme(AppTheme.dark),
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
    final expected = GlassFilter.of(
      GlassTheme.bar(tester.element(find.byType(Scaffold))).blurSigma,
      saturation: GlassTheme.bar(
        tester.element(find.byType(Scaffold)),
      ).saturation,
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

  testWidgets('a cover scrolled out of sight does not fly back', (
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

    await scrollTo(tester, controller, 100);
    expect(heroOn(), isTrue, reason: 'still partly in sight');

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
