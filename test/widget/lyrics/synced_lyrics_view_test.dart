import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics.dart';
import 'package:troona/features/lyrics/presentation/widgets/synced_lyrics_view.dart';
import 'package:troona/l10n/app_localizations.dart';

import '../../helpers/roboto.dart';

final _lyrics = SyncedLyrics([
  for (var i = 0; i < 40; i++)
    LyricLine(
      Duration(seconds: 1 + i * 3),
      i == 7
          ? 'A very long line that wraps on a small phone, with more words '
                'after it and still more, to see it wrap three times at least'
          : (i == 12 ? '' : 'Line $i'),
    ),
], source: LyricsSource.online);

void main() {
  setUpAll(loadRoboto);

  late ValueNotifier<int> active;
  late List<Duration> seeks;

  Future<void> pump(
    WidgetTester tester, {
    double scale = 1,
    bool still = false,
    SyncedLyrics? lyrics,
  }) async {
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = const Size(360, 640) * 3;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    active = ValueNotifier(-1);
    addTearDown(active.dispose);
    seeks = [];
    await tester.pumpWidget(
      MaterialApp(
        theme: robotoTheme(AppTheme.dark),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(360, 640),
            textScaler: TextScaler.linear(scale),
            disableAnimations: still,
          ),
          child: Scaffold(
            body: SizedBox(
              height: 400,
              child: SyncedLyricsView(
                lyrics: lyrics ?? _lyrics,
                activeLine: active,
                seekTargetOf: (line) =>
                    line.at - const Duration(milliseconds: 200),
                onSeek: seeks.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double scrollOffset(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('360 x 640, text x$scale: a long line wraps, nothing '
        'overflows', (tester) async {
      await pump(tester, scale: scale);
      active.value = 7;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('A very long line'), findsOneWidget);
    });
  }

  testWidgets('the line sung is brought to a third of the height', (
    tester,
  ) async {
    await pump(tester);
    expect(scrollOffset(tester), 0);
    active.value = 10;
    await tester.pumpAndSettle();
    final line = tester.getTopLeft(find.text('Line 10')).dy;
    final view = tester.getTopLeft(find.byType(SyncedLyricsView)).dy;
    // The line's top, past its padding, at 35 % of 400.
    expect(line - view, closeTo(400 * SyncedLyricsView.anchor + 9, 2));
  });

  testWidgets('a tap seeks to the line, corrected', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Line 2'));
    expect(seeks, [const Duration(milliseconds: 6800)]);
  });

  testWidgets('a finger stops the follow, a pill offers to come back, and '
      'it comes back by itself after 4 s', (tester) async {
    await pump(tester);
    active.value = 5;
    await tester.pumpAndSettle();
    await tester.drag(find.byType(SyncedLyricsView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Back to the current line'), findsOneWidget);
    final moved = scrollOffset(tester);

    // A new line while the finger's place is kept: no jump.
    active.value = 6;
    await tester.pumpAndSettle();
    expect(scrollOffset(tester), moved);

    await tester.pump(SyncedLyricsView.resumeAfter);
    await tester.pumpAndSettle();
    expect(find.text('Back to the current line'), findsNothing);
    expect(scrollOffset(tester), isNot(moved));
  });

  testWidgets('the pill brings the line back at once', (tester) async {
    await pump(tester);
    active.value = 5;
    await tester.pumpAndSettle();
    final following = scrollOffset(tester);
    await tester.drag(find.byType(SyncedLyricsView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to the current line'));
    await tester.pumpAndSettle();
    expect(scrollOffset(tester), closeTo(following, 1));
    expect(find.text('Back to the current line'), findsNothing);
  });

  testWidgets('a timed pause shows the instrumental dots', (tester) async {
    await pump(tester);
    expect(find.bySemanticsLabel('Instrumental'), findsOneWidget);
  });

  testWidgets('a long intro starts with the dots', (tester) async {
    await pump(
      tester,
      lyrics: const SyncedLyrics([
        LyricLine(Duration(seconds: 12), 'Late start'),
      ], source: LyricsSource.online),
    );
    expect(find.bySemanticsLabel('Instrumental'), findsOneWidget);
  });

  testWidgets('with less motion, no line is scaled', (tester) async {
    await pump(tester, still: true);
    active.value = 3;
    await tester.pumpAndSettle();
    final scales = tester
        .widgetList<Transform>(
          find.ancestor(
            of: find.text('Line 9'),
            matching: find.byType(Transform),
          ),
        )
        .map((t) => t.transform.getMaxScaleOnAxis());
    expect(scales, everyElement(1.0));
  });

  testWidgets('a screen reader hears each line and where it leads', (
    tester,
  ) async {
    await pump(tester);
    expect(
      tester.getSemantics(find.text('Line 2')),
      matchesSemantics(
        label: 'Line 2',
        hint: 'Go to 0:06',
        isButton: true,
        hasTapAction: true,
      ),
    );
  });
}
