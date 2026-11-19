import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/shared/widgets/glass_bottom_sheet.dart';
import 'package:troona/shared/widgets/glass_card.dart';
import 'package:troona/shared/widgets/glass_edge.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';

/// The [GlassEdgePainter]s drawn under [of].
Iterable<GlassEdgePainter> _edgesOf(WidgetTester tester, Finder of) => tester
    .widgetList<CustomPaint>(
      find.descendant(of: of, matching: find.byType(CustomPaint)),
    )
    .map((p) => p.foregroundPainter)
    .whereType<GlassEdgePainter>();

void main() {
  Widget app(Widget child, {GlassQuality glass = GlassQuality.high}) =>
      MaterialApp(
        theme: AppTheme.withGlass(glass),
        home: Scaffold(body: Center(child: child)),
      );

  for (final glass in [GlassQuality.high, GlassQuality.off]) {
    testWidgets('${glass.name}: cards, round buttons and sheets draw one '
        'edge, the same one', (tester) async {
      await tester.pumpWidget(
        app(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassCard(child: SizedBox(width: 100, height: 40)),
              GlassIconButton(icon: AppIcons.more, tooltip: 'More'),
              SizedBox(
                width: 300,
                child: GlassBottomSheet(child: SizedBox(height: 40)),
              ),
            ],
          ),
          glass: glass,
        ),
      );
      for (final surface in [GlassCard, GlassIconButton, GlassBottomSheet]) {
        final edges = _edgesOf(tester, find.byType(surface));
        expect(edges, hasLength(1), reason: '$surface');
        expect(edges.single.width, greaterThan(0), reason: '$surface');
        expect(edges.single.top.a, greaterThan(0), reason: '$surface');
      }
      // The round button's edge follows its circle.
      final button = _edgesOf(tester, find.byType(GlassIconButton)).single;
      final size = tester.getSize(
        find
            .descendant(
              of: find.byType(GlassIconButton),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(button.borderRadius, BorderRadius.circular(size.width / 2));
    });
  }

  testWidgets('the edge is one stroke of its width', (tester) async {
    const painter = GlassEdgePainter(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      top: Color(0x22FFFFFF),
      sides: Color(0x0DFFFFFF),
      width: 1,
    );
    await tester.pumpWidget(
      const Center(
        child: CustomPaint(size: Size(100, 40), foregroundPainter: painter),
      ),
    );
    expect(
      tester.renderObject(find.byType(CustomPaint).last),
      paints..rrect(style: PaintingStyle.stroke, strokeWidth: 1),
    );
  });

  testWidgets('no width, no edge', (tester) async {
    await tester.pumpWidget(
      const Center(
        child: CustomPaint(
          size: Size(100, 40),
          foregroundPainter: GlassEdgePainter(
            borderRadius: BorderRadius.zero,
            top: Color(0x22FFFFFF),
            sides: Color(0x0DFFFFFF),
            width: 0,
          ),
        ),
      ),
    );
    expect(tester.renderObject(find.byType(CustomPaint).last), paintsNothing);
  });

  testWidgets('the shadow is painted outside the surface only, as far as '
      'it reaches, so a blur under it does not take it in', (tester) async {
    const painter = OuterShadowPainter(
      borderRadius: BorderRadius.all(Radius.circular(24)),
    );
    await tester.pumpWidget(
      const Center(
        child: CustomPaint(size: Size(200, 60), foregroundPainter: painter),
      ),
    );
    final box = tester.renderObject(find.byType(CustomPaint).last);
    late Path clip;
    late RRect drawn;
    expect(
      box,
      paints
        ..something((method, args) {
          if (method != #clipPath) return false;
          clip = args.first as Path;
          return true;
        })
        ..something((method, args) {
          if (method != #drawRRect) return false;
          drawn = args.first as RRect;
          return true;
        }),
    );
    // The surface is left out, its rounded corners' outside is in.
    expect(clip.contains(const Offset(100, 30)), isFalse);
    expect(clip.contains(const Offset(2, 30)), isFalse);
    expect(clip.contains(const Offset(1, 1)), isTrue, reason: 'corner');
    // The band reaches as far as the blurred, shifted shadow.
    final reach = painter.blurSigma * 3 + painter.offset.dy;
    expect(clip.contains(Offset(100, 60 + reach - 1)), isTrue);
    expect(clip.contains(Offset(-reach + 1, 30)), isTrue);
    // The shadow is the surface, moved down.
    expect(drawn.outerRect, const Rect.fromLTWH(0, 8, 200, 60));
  });
}
