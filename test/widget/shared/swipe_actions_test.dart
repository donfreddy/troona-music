import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/shared/widgets/swipe_actions.dart';

void main() {
  late List<String> ticks;
  late List<String> fired;
  var taps = 0;
  const rowKey = ValueKey('row');

  setUp(() {
    ticks = [];
    fired = [];
    taps = 0;
  });

  Future<void> pump(
    WidgetTester tester, {
    bool left = true,
    bool right = true,
  }) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          ticks.add(call.arguments as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SwipeActions(
              onSwipeLeft: left ? () => fired.add('left') : null,
              onSwipeRight: right ? () => fired.add('right') : null,
              background: (_, direction, progress, armed) =>
                  Text('bg ${direction.name} ${armed ? 'armed' : ''}'),
              child: GestureDetector(
                onTap: () => taps++,
                child: const SizedBox(
                  key: rowKey,
                  width: 300,
                  height: 56,
                  child: Text('row'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double rowX(WidgetTester tester) => tester.getTopLeft(find.byKey(rowKey)).dx;

  testWidgets('past the threshold: a tick, the action on release, and the '
      'row springs back', (tester) async {
    await pump(tester);
    final rest = rowX(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(rowKey)),
    );
    // Slowly, so it is not a fling.
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(-10, 0));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('bg left armed'), findsOneWidget);
    expect(ticks, hasLength(1), reason: 'one tick on crossing');
    expect(fired, isEmpty, reason: 'not before the finger lets go');

    await gesture.up();
    await tester.pumpAndSettle();
    expect(fired, ['left']);
    expect(ticks, hasLength(1));
    expect(rowX(tester), rest);
  });

  testWidgets('short and slow: nothing', (tester) async {
    await pump(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(rowKey)),
    );
    for (var i = 0; i < 4; i++) {
      await gesture.moveBy(const Offset(10, 0));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(fired, isEmpty);
    expect(ticks, isEmpty);
  });

  testWidgets('back under the threshold before letting go: nothing, a tick '
      'each way', (tester) async {
    await pump(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(rowKey)),
    );
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(10, 0));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('bg right armed'), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(-10, 0));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(fired, isEmpty);
    expect(ticks, hasLength(2));
  });

  testWidgets('a quick fling runs it, however short', (tester) async {
    await pump(tester);
    // 50 dp in 40 ms: well past the fling speed, short of the threshold.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(rowKey)),
    );
    for (var i = 1; i <= 5; i++) {
      await gesture.moveBy(
        const Offset(10, 0),
        timeStamp: Duration(milliseconds: 8 * i),
      );
    }
    await gesture.up(timeStamp: const Duration(milliseconds: 40));
    await tester.pumpAndSettle();
    expect(fired, ['right']);
  });

  testWidgets('a way with no action resists and runs nothing', (tester) async {
    await pump(tester, left: false);
    final rest = rowX(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(rowKey)),
    );
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(-10, 0));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(rest - rowX(tester), lessThan(30));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(fired, isEmpty);
    expect(ticks, isEmpty);
  });

  testWidgets('a tap still reaches the row', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(rowKey));
    expect(taps, 1);
    expect(fired, isEmpty);
  });
}
