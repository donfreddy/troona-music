import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/shared/widgets/marquee.dart';

/// The test font draws every glyph as a square: 10 px per character.
const _style = TextStyle(fontSize: 10);
const _pause = Duration(seconds: 2);
const _short = 'Fits'; // 40 px
final _long = 'Way too long ' * 3; // 390 px

void main() {
  Future<void> pump(
    WidgetTester tester,
    String text, {
    double width = 200,
    bool reduceMotion = false,
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          disableAnimations: reduceMotion,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Directionality(
          textDirection: direction,
          child: Center(
            child: SizedBox(
              width: width,
              child: Marquee(text: text, style: _style, pause: _pause),
            ),
          ),
        ),
      ),
    );
    await tester.pump(); // the loop starts after the first layout
  }

  Finder scrolling() => find.descendant(
    of: find.byType(Marquee),
    matching: find.byType(CustomPaint),
  );

  testWidgets('fitting text stays a static text, nothing ticks', (
    tester,
  ) async {
    await pump(tester, _short);

    expect(find.text(_short), findsOneWidget);
    expect(scrolling(), findsNothing);
    await tester.pump(_pause * 2);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('overflowing text rests, then scrolls', (tester) async {
    await pump(tester, _long);

    expect(scrolling(), findsOneWidget);
    expect(find.bySemanticsLabel(_long), findsOneWidget);
    // Resting: no frame is produced during the pause.
    await tester.pump(_pause - const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('a loop ends at rest, then starts over', (tester) async {
    await pump(tester, _long);
    // 390 px of text + 40 px of gap at 32 px/s.
    const run = Duration(milliseconds: 430 * 1000 ~/ 32);

    await tester.pump(_pause);
    await tester.pump(run);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'resting');

    await tester.pump(_pause);
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('text that comes to fit stops scrolling', (tester) async {
    await pump(tester, _long);
    await tester.pump(_pause + const Duration(seconds: 1));

    await pump(tester, _short);

    expect(find.text(_short), findsOneWidget);
    await tester.pump(_pause * 2);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('more room makes overflowing text static', (tester) async {
    await pump(tester, _long);

    await pump(tester, _long, width: 500);

    expect(find.text(_long), findsOneWidget);
    expect(scrolling(), findsNothing);
  });

  testWidgets('a new text rests again before scrolling', (tester) async {
    await pump(tester, _long);
    await tester.pump(_pause + const Duration(seconds: 1));

    await pump(tester, '$_long again');
    await tester.pump(_pause - const Duration(milliseconds: 100));

    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  group('painted', () {
    // 390 px of text + 40 px of gap: the copy starts 430 px after it.
    const period = 430.0;
    const run = Duration(milliseconds: 430 * 1000 ~/ 32);
    Matcher near(Offset offset, [double epsilon = 0.05]) =>
        offsetMoreOrLessEquals(offset, epsilon: epsilon);
    RenderObject painter(WidgetTester tester) =>
        tester.renderObject(scrolling());

    /// Into the run by [elapsed]; the run starts on the frame after the
    /// pause, its first tick.
    Future<void> runFor(WidgetTester tester, Duration elapsed) async {
      await tester.pump(_pause);
      await tester.pump();
      await tester.pump(elapsed);
    }

    testWidgets('at rest, the text at the start, its copy after it', (
      tester,
    ) async {
      await pump(tester, _long);

      expect(
        painter(tester),
        paints
          ..paragraph(offset: near(Offset.zero))
          ..paragraph(offset: near(Offset(period, 0))),
      );
    });

    testWidgets('halfway, both moved by half a period', (tester) async {
      await pump(tester, _long);
      await runFor(tester, run ~/ 2);

      expect(
        painter(tester),
        paints
          ..paragraph(offset: near(Offset(-period / 2, 0)))
          ..paragraph(offset: near(Offset(period / 2, 0))),
      );
    });

    testWidgets('the end of a run draws the start again', (tester) async {
      await pump(tester, _long);
      await runFor(tester, run - const Duration(milliseconds: 1));

      // A moment before the end: the copy is where the text started.
      expect(
        painter(tester),
        paints
          ..paragraph(offset: near(const Offset(-period, 0), 0.1))
          ..paragraph(offset: near(Offset.zero, 0.1)),
      );

      await tester.pump(const Duration(milliseconds: 10));
      expect(
        painter(tester),
        paints
          ..paragraph(offset: near(Offset.zero))
          ..paragraph(offset: near(const Offset(period, 0))),
      );
    });

    testWidgets('right to left, the text moves right', (tester) async {
      await pump(tester, _long, direction: TextDirection.rtl);
      // Right-aligned at rest (200 - 390), copy on its left.
      const start = 200 - 390.0;
      expect(
        painter(tester),
        paints
          ..paragraph(offset: near(Offset(start, 0)))
          ..paragraph(offset: near(Offset(start - period, 0))),
      );

      await runFor(tester, run ~/ 2);
      expect(
        painter(tester),
        paints
          ..paragraph(offset: near(Offset(start + period / 2, 0)))
          ..paragraph(offset: near(Offset(start - period / 2, 0))),
      );
    });
  });

  testWidgets('a longer text mid-run rests, then runs at the same speed', (
    tester,
  ) async {
    await pump(tester, _long);
    await tester.pump(_pause + const Duration(seconds: 1));

    // Twice as wide: 780 px of text, so the copy is 820 px after it.
    await pump(tester, _long, textScale: 2);
    await tester.pump(_pause - const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'resting');

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    // About 10 s at 32 px/s, ramp included: a little over 300 px. A run
    // timed for the old period would be past 600 px.
    expect(
      tester.renderObject(
        find.descendant(
          of: find.byType(Marquee),
          matching: find.byType(CustomPaint),
        ),
      ),
      paints..paragraph(
        offset: offsetMoreOrLessEquals(const Offset(-317, 0), epsilon: 5),
      ),
    );
  });

  testWidgets('a letter spacing override is measured too', (tester) async {
    // 30 characters, 150 px: fits in 200 px, unless each one gets 3 px more.
    final text = 'x' * 30;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(letterSpacingOverride: 3),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 200,
              child: Marquee(
                text: text,
                style: const TextStyle(fontSize: 5),
                pause: _pause,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(scrolling(), findsOneWidget);
  });

  testWidgets('no room at all: static text, nothing ticks', (tester) async {
    await pump(tester, _long, width: 0);

    expect(tester.takeException(), isNull);
    expect(scrolling(), findsNothing);
    await tester.pump(_pause * 2);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('reduced motion ellipsizes instead of scrolling', (tester) async {
    await pump(tester, _long, reduceMotion: true);

    expect(scrolling(), findsNothing);
    final text = tester.widget<Text>(find.text(_long));
    expect(text.overflow, TextOverflow.ellipsis);
    await tester.pump(_pause * 2);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
