import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/components/glass_filter.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
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

  testWidgets("a card that blurs takes its material's saturation and "
      'exposure, not the decorative boost', (tester) async {
    const config = GlassConfig(
      blurSigma: 20,
      fill: Color(0x26000000),
      border: Color(0x22FFFFFF),
      highlight: Color(0x0DFFFFFF),
      saturation: 1.25,
      exposure: .5,
    );
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: GlassCard(config: config, child: SizedBox.square(dimension: 50)),
      ),
    );
    final backdrop = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
    expect(backdrop.filter, GlassFilter.of(20, saturation: 1.25, exposure: .5));
    expect(backdrop.filter, isNot(GlassFilter.of(20)));
  });
}
