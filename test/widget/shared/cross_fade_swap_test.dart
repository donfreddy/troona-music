import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/shared/widgets/cross_fade_swap.dart';

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  var taps = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => taps++),
    child: SizedBox(width: 100, height: 40, child: Text('taps $taps')),
  );
}

void main() {
  Future<void> pump(WidgetTester tester, {required bool on}) =>
      tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: CrossFadeSwap(
              // Small, in a corner: what it leaves open must not reach
              // the child either.
              alt: on
                  ? const Align(
                      alignment: Alignment.bottomRight,
                      child: Text('alt', style: TextStyle(fontSize: 8)),
                    )
                  : null,
              child: const _Counter(),
            ),
          ),
        ),
      );

  testWidgets('the child keeps its state under the alt', (tester) async {
    await pump(tester, on: false);
    await tester.tap(find.text('taps 0'));
    await tester.pump();

    await pump(tester, on: true);
    await tester.pumpAndSettle();
    expect(find.text('alt'), findsOneWidget);
    // Covered, it takes no touch.
    await tester.tap(find.text('taps 1'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('taps 1'), findsOneWidget);

    await pump(tester, on: false);
    await tester.pumpAndSettle();
    expect(find.text('taps 1'), findsOneWidget);
  });

  testWidgets('the alt fades out as it was, then goes', (tester) async {
    await pump(tester, on: true);
    await tester.pumpAndSettle();
    await pump(tester, on: false);
    await tester.pump(CrossFadeSwap.duration ~/ 2);
    // Still there while it fades.
    expect(find.text('alt'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('alt'), findsNothing);
  });
}
