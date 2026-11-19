import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/shared/widgets/rolling_count.dart';

void main() {
  Future<void> pump(WidgetTester tester, int value, {bool reduce = false}) =>
      tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: reduce),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: RollingCount(value)),
          ),
        ),
      );

  /// The vertical offset of [digit]'s slot, in its own heights.
  double offsetOf(WidgetTester tester, String digit) => tester
      .widget<FractionalTranslation>(
        find.ancestor(
          of: find.text(digit),
          matching: find.byType(FractionalTranslation),
        ),
      )
      .translation
      .dy;

  testWidgets('growing, the new digit comes from below', (tester) async {
    await pump(tester, 1);
    await pump(tester, 2);
    await tester.pump(RollingCount.duration ~/ 4);
    expect(offsetOf(tester, '2'), greaterThan(0));
    expect(offsetOf(tester, '1'), lessThan(0));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsNothing);
    expect(find.byType(FractionalTranslation), findsNothing);
  });

  testWidgets('shrinking, it comes from above', (tester) async {
    await pump(tester, 3);
    await pump(tester, 2);
    await tester.pump(RollingCount.duration ~/ 4);
    expect(offsetOf(tester, '2'), lessThan(0));
    expect(offsetOf(tester, '3'), greaterThan(0));
    await tester.pumpAndSettle();
  });

  testWidgets('only the places that change roll', (tester) async {
    await pump(tester, 10);
    await pump(tester, 11);
    await tester.pump(RollingCount.duration ~/ 4);
    // The tens digit stays still; the units roll from 0 to 1.
    expect(find.byType(FractionalTranslation), findsNWidgets(2));
    expect(offsetOf(tester, '0'), lessThan(0));
    await tester.pumpAndSettle();

    await pump(tester, 9);
    await tester.pump(RollingCount.duration ~/ 4);
    // 11 to 9: the units roll down, the tens place goes.
    expect(offsetOf(tester, '9'), lessThan(0));
    await tester.pumpAndSettle();
    expect(find.text('9'), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });

  testWidgets('a place coming does not roll; the units do', (tester) async {
    await pump(tester, 9);
    await pump(tester, 10);
    await tester.pump(RollingCount.duration ~/ 4);
    // The units roll from 9 to 0; the tens come in place.
    expect(offsetOf(tester, '0'), greaterThan(0));
    expect(offsetOf(tester, '9'), lessThan(0));
    expect(
      find.ancestor(
        of: find.text('1'),
        matching: find.byType(FractionalTranslation),
      ),
      findsNothing,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('with reduced motion the digit changes in place', (
    tester,
  ) async {
    await pump(tester, 1, reduce: true);
    await pump(tester, 2, reduce: true);
    await tester.pump();
    expect(find.byType(FractionalTranslation), findsNothing);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });
}
