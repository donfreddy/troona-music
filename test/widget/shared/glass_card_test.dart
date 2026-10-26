import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/shared/widgets/glass_card.dart';

void main() {
  Future<RenderObject> pumpCard(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Center(
          child: SizedBox(
            width: 200,
            height: 100,
            child: GlassCard(child: SizedBox()),
          ),
        ),
      ),
    );
    return tester.renderObject(
      find
          .descendant(
            of: find.byType(GlassCard),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
  }

  testWidgets('a card is flat by default', (tester) async {
    await pumpCard(tester);
    expect(
      find.descendant(
        of: find.byType(GlassCard),
        matching: find.byType(BackdropFilter),
      ),
      findsNothing,
    );
  });

  testWidgets('the edge is one stroke, with no clipping', (tester) async {
    final paint = await pumpCard(tester);
    // The fill and the edge: one rounded rect each.
    expect(paint, paintsExactlyCountTimes(#drawRRect, 2));
    expect(paint, isNot(paints..clipRect()));
  });
}
