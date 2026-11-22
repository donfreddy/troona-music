import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/semantic/palette_ink.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/lyrics/presentation/widgets/synced_lyrics_view.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/dynamic_background.dart';
import 'package:troona/shared/widgets/palette_ink_scope.dart';

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

const _red = Color(0xFF7A1020);
const _blue = Color(0xFF102A7A);
const _edge = Color(0xFF301040);

PaletteInk _inkOf(Color a) => PaletteInk.of(
  DynamicBackground.fitForText(a),
  DynamicBackground.fitForText(_edge),
);

void main() {
  setUpAll(loadRoboto);

  late ValueNotifier<int> active;
  late ValueNotifier<PlaybackProgress> position;
  late List<Duration> seeks;
  late ValueNotifier<Color> glow;

  Future<void> pump(
    WidgetTester tester, {
    double scale = 1,
    bool still = false,
    SyncedLyrics? lyrics,
    Duration at = Duration.zero,
    bool settle = true,
  }) async {
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = const Size(360, 640) * 3;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    active = ValueNotifier(-1);
    addTearDown(active.dispose);
    position = ValueNotifier(
      PlaybackProgress(
        position: at,
        buffered: Duration.zero,
        duration: const Duration(minutes: 3),
      ),
    );
    addTearDown(position.dispose);
    seeks = [];
    glow = ValueNotifier(_red);
    addTearDown(glow.dispose);
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
            body: ValueListenableBuilder<Color>(
              valueListenable: glow,
              builder: (_, color, child) => PaletteInkScope(
                colorA: color,
                colorB: _edge,
                tone: DynamicBackgroundTone.immersive,
                child: child!,
              ),
              child: SizedBox(
                height: 400,
                child: SyncedLyricsView(
                  lyrics: lyrics ?? _lyrics,
                  activeLine: active,
                  position: position,
                  seekTargetOf: (line) =>
                      line.at - const Duration(milliseconds: 200),
                  onSeek: seeks.add,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
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

  /// A dot [filled] of the way from unlit (far) to lit (the line sung).
  int lit(double filled) {
    final ink = _inkOf(_red);
    return Color.lerp(ink.far, ink.primary, filled)!.toARGB32();
  }

  /// How the three dots of the first passage with no singing are painted.
  List<int> dots(WidgetTester tester) {
    final painter = tester
        .widget<CustomPaint>(
          find
              .descendant(
                of: find.bySemanticsLabel('Instrumental').first,
                matching: find.byType(CustomPaint),
              )
              .first,
        )
        .painter!;
    // The painter exposes nothing: read what it draws.
    final canvas = _DotsCanvas();
    painter.paint(canvas, const Size(46, 10));
    // As drawn: 8 bits a channel.
    return [for (final c in canvas.colors) c.toARGB32()];
  }

  testWidgets('the dots of an intro fill one after the other as it goes, '
      'the last as the singing comes', (tester) async {
    const intro = SyncedLyrics([
      LyricLine(Duration(seconds: 12), 'Late start'),
    ], source: LyricsSource.online);
    // The first line is sought 200 ms early in this test: 11.8 s of intro.
    await pump(tester, lyrics: intro);
    expect(dots(tester), [lit(0), lit(0), lit(0)], reason: 'at the very start');

    position.value = const PlaybackProgress(
      position: Duration(milliseconds: 5900),
      buffered: Duration.zero,
      duration: Duration(minutes: 3),
    );
    await tester.pump();
    final half = dots(tester);
    expect(half[0], lit(1), reason: 'the first third is over');
    // Half way, within the rounding of one channel step.
    for (var shift = 0; shift < 32; shift += 8) {
      expect(
        (half[1] >> shift) & 0xFF,
        closeTo((lit(0.5) >> shift) & 0xFF, 1),
        reason: 'half of the second',
      );
    }
    expect(half[2], lit(0));

    position.value = const PlaybackProgress(
      position: Duration(milliseconds: 11800),
      buffered: Duration.zero,
      duration: Duration(minutes: 3),
    );
    await tester.pump();
    expect(dots(tester), [lit(1), lit(1), lit(1)]);
  });

  testWidgets('dots not being played are dim, whatever the position', (
    tester,
  ) async {
    await pump(tester, at: const Duration(seconds: 100));
    active.value = 0;
    await tester.pumpAndSettle();
    expect(dots(tester), [lit(0), lit(0), lit(0)]);
  });

  testWidgets('with less motion the dots are simply lit while played', (
    tester,
  ) async {
    await pump(
      tester,
      still: true,
      lyrics: const SyncedLyrics([
        LyricLine(Duration(seconds: 12), 'Late start'),
      ], source: LyricsSource.online),
    );
    expect(dots(tester), [lit(1), lit(1), lit(1)]);
  });

  /// How much of the lines shows, as painted in this frame.
  double linesOpacity(WidgetTester tester) => tester
      .widget<FadeTransition>(
        find
            .descendant(
              of: find.byType(AnimatedOpacity).first,
              matching: find.byType(FadeTransition),
            )
            .first,
      )
      .opacity
      .value;

  testWidgets('the lines show only once placed on the line sung', (
    tester,
  ) async {
    await pump(tester, settle: false);
    expect(linesOpacity(tester), 0, reason: 'the frame they are laid out in');
    await tester.pumpAndSettle();
    expect(linesOpacity(tester), 1);
  });

  testWidgets('other lyrics in the same place (an import over the ones '
      'shown) are hidden at once, until placed', (tester) async {
    await pump(tester);
    active.value = 14;
    await tester.pumpAndSettle();
    expect(scrollOffset(tester), greaterThan(0));
    await pump(
      tester,
      settle: false,
      lyrics: const SyncedLyrics([
        LyricLine(Duration(seconds: 1), 'Other words'),
        LyricLine(Duration(seconds: 4), 'Other again'),
      ], source: LyricsSource.imported),
    );
    expect(linesOpacity(tester), 0, reason: 'still at the old place');
    await tester.pumpAndSettle();
    expect(linesOpacity(tester), 1);
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

  Color? colorOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.color;

  testWidgets('lines take tints of the glow: the line sung white, the two '
      'around it near, the rest far', (tester) async {
    await pump(tester);
    active.value = 5;
    await tester.pumpAndSettle();
    final ink = _inkOf(_red);
    expect(colorOf(tester, 'Line 5'), ink.primary);
    expect(colorOf(tester, 'Line 4'), ink.near);
    expect(colorOf(tester, 'Line 6'), ink.near);
    expect(colorOf(tester, 'Line 3'), ink.near);
    expect(colorOf(tester, 'Line 2'), ink.far);
    expect(colorOf(tester, 'Line 9'), ink.far);
    // A red glow gives a red tint, not a grey.
    final near = colorOf(tester, 'Line 6')!;
    expect(near.r, greaterThan(near.b));
  });

  testWidgets('a new song: the lines follow its glow', (tester) async {
    await pump(tester);
    active.value = 5;
    await tester.pumpAndSettle();
    glow.value = _blue;
    await tester.pumpAndSettle();
    final near = colorOf(tester, 'Line 6')!;
    expect(near, _inkOf(_blue).near);
    expect(near.b, greaterThan(near.r));
  });
}

/// Records the colour of each circle drawn.
class _DotsCanvas implements Canvas {
  final colors = <Color>[];

  @override
  void drawCircle(Offset c, double radius, Paint paint) =>
      colors.add(paint.color);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
