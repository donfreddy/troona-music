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

  Future<ScrollController> pump(
    WidgetTester tester,
    GlassSliverHeader header, {
    double textScale = 1,
    GlassQuality quality = GlassQuality.high,
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
          body: CustomScrollView(
            controller: controller,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              header,
              SliverList.builder(
                itemCount: 40,
                itemBuilder: (_, i) => SizedBox(
                  key: i == 0 ? firstRowKey : null,
                  height: 56,
                  child: Text('Row $i'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
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

  testWidgets('collapsing switches the blur on at one sigma, and the bar '
      'takes the compact title', (tester) async {
    final controller = await pump(tester, largeTitle());
    final expected = GlassFilter.of(
      GlassTheme.bar(tester.element(find.byType(Scaffold))).blurSigma,
      saturation: GlassTheme.bar(
        tester.element(find.byType(Scaffold)),
      ).saturation,
    );

    await scrollTo(tester, controller, GlassSliverHeader.largeTitleHeight / 2);
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

    await scrollTo(tester, controller, 180);
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
}
