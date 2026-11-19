import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/shared/widgets/edge_fade.dart';

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) => Text('$count');
}

void main() {
  group('stopsFor', () {
    test('fades each edge over its own width', () {
      expect(EdgeFade.stopsFor(200, start: 12, end: 16), [
        0,
        12 / 200,
        1 - 16 / 200,
        1,
      ]);
    });

    test('too narrow for both, the fades meet: stops never go back', () {
      final stops = EdgeFade.stopsFor(20, start: 12, end: 16);
      expect(stops, [0, .5, .5, 1]);
      expect(EdgeFade.stopsFor(0, start: 12, end: 16), [0, .5, .5, 1]);
    });
  });

  Future<void> pump(WidgetTester tester, {required bool active}) =>
      tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 200,
              height: 20,
              child: EdgeFade(
                active: active,
                start: 12,
                end: 16,
                child: const _Counter(),
              ),
            ),
          ),
        ),
      );

  int masks(WidgetTester tester) =>
      tester.layers.whereType<ShaderMaskLayer>().length;

  testWidgets('a mask layer only while active, over the whole child', (
    tester,
  ) async {
    await pump(tester, active: false);
    expect(masks(tester), 0);

    await pump(tester, active: true);
    final layer = tester.layers.whereType<ShaderMaskLayer>().single;
    expect(layer.blendMode, BlendMode.dstIn);
    expect(layer.maskRect, tester.getRect(find.byType(EdgeFade)));

    await pump(tester, active: false);
    expect(masks(tester), 0);
  });

  testWidgets('turning on and off keeps the child and its state', (
    tester,
  ) async {
    await pump(tester, active: false);
    tester.state<_CounterState>(find.byType(_Counter)).count = 7;
    await pump(tester, active: true);
    await pump(tester, active: false);
    expect(tester.state<_CounterState>(find.byType(_Counter)).count, 7);
  });
}
