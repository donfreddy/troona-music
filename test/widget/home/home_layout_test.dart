import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/home/presentation/widgets/home_hero_banner.dart';
import 'package:troona/features/home/presentation/widgets/quick_access_row.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/l10n/app_localizations_fr.dart';

import '../../helpers/fake_player.dart';
import '../../helpers/roboto.dart';

void main() {
  /// French labels are the longest; a 360 dp wide phone.
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double width = 360,
    double textScale = AppLayout.maxTextScale,
  }) async {
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = Size(width, 640) * 3;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        // The app leaves the family to the system, Roboto on Android.
        theme: robotoTheme(AppTheme.dark),
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SafeArea(child: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  final fr = AppLocalizationsFr();
  final labels = [fr.likedSongs, fr.actionShuffle, fr.homeQuickRecent];

  setUpAll(loadRoboto);

  /// Each chip's label, laid out: not cut, and the chips' sizes.
  List<Rect> chips(WidgetTester tester) {
    expect(tester.takeException(), isNull);
    for (final label in labels) {
      final text = tester.renderObject<RenderParagraph>(find.text(label));
      expect(text.didExceedMaxLines, isFalse, reason: label);
    }
    return [
      for (final label in labels)
        tester.getRect(
          find
              .ancestor(of: find.text(label), matching: find.byType(Container))
              .first,
        ),
    ];
  }

  for (final (width, scale) in [
    (360.0, 1.0),
    (360.0, AppLayout.maxTextScale),
    (390.0, 1.0),
    (412.0, AppLayout.maxTextScale),
  ]) {
    testWidgets('quick chips: ${width}dp, text x$scale, whole labels in three '
        'equal columns', (tester) async {
      await pump(
        tester,
        const QuickAccessRow(likesCount: 12, totalTracks: 40),
        width: width,
        textScale: scale,
      );
      final rects = chips(tester);
      expect({for (final r in rects) r.width.round()}, hasLength(1));
      expect({for (final r in rects) r.height.round()}, hasLength(1));
      expect(rects.last.right, lessThanOrEqualTo(width - 16 + 0.5));
    });
  }

  testWidgets('the resume card grows instead of overflowing', (tester) async {
    await pump(
      tester,
      HomeHeroBanner(
        lastPlayed: testTrack('a', durationMs: 180000),
        totalTracks: 40,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick chips stack, whole labels, with the largest font', (
    tester,
  ) async {
    // Home is not capped: the system's largest sizes reach it.
    await pump(
      tester,
      const QuickAccessRow(likesCount: 12, totalTracks: 40),
      textScale: 2,
    );
    final rects = chips(tester);
    for (final r in rects) {
      expect(r.width, closeTo(360 - 2 * 16, 0.5));
    }
    expect(rects[0].bottom, lessThanOrEqualTo(rects[1].top));
    expect(rects[1].bottom, lessThanOrEqualTo(rects[2].top));
  });

  testWidgets('the resume card grows with the largest font', (tester) async {
    await pump(
      tester,
      HomeHeroBanner(
        lastPlayed: testTrack('a', durationMs: 180000),
        totalTracks: 40,
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
