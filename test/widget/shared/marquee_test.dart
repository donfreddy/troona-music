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
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Directionality(
          textDirection: TextDirection.ltr,
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

  testWidgets('reduced motion ellipsizes instead of scrolling', (
    tester,
  ) async {
    await pump(tester, _long, reduceMotion: true);

    expect(scrolling(), findsNothing);
    final text = tester.widget<Text>(find.text(_long));
    expect(text.overflow, TextOverflow.ellipsis);
    await tester.pump(_pause * 2);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
