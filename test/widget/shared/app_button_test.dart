import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/shared/widgets/app_button.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(body: Center(child: child)),
);

/// The drawn pill: the shaped box inside the button.
Finder _pill(String label) => find.ancestor(
  of: find.textContaining(label, findRichText: true),
  matching: find.byWidgetPredicate(
    (w) => w is AnimatedContainer && w.decoration is ShapeDecoration,
  ),
);

void main() {
  testWidgets('a small pill is 32 dp high in a 44 dp touch target; a medium '
      'one is 44 dp', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton.secondary(
              'See all',
              size: AppButtonSize.small,
              onPressed: () => taps++,
            ),
            AppButton.primary('Play', onPressed: () {}),
          ],
        ),
      ),
    );

    final small = find.widgetWithText(TextButton, 'See all');
    expect(tester.getSize(small).height, 44);
    expect(tester.getSize(_pill('See all')).height, 32);
    expect(tester.getSize(_pill('Play')).height, 44);

    // Just above the pill, still in the touch target.
    final pill = tester.getRect(_pill('See all'));
    await tester.tapAt(Offset(pill.center.dx, pill.top - 4));
    expect(taps, 1);
  });

  testWidgets('disabled: no tap, button semantics without enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const AppButton.primary('Play', onPressed: null)),
    );
    await tester.tap(find.text('Play', findRichText: true));
    expect(
      tester.getSemantics(find.byType(TextButton)),
      isSemantics(label: 'Play', isButton: true, isEnabled: false),
    );
  });

  testWidgets('expanded fills the width; otherwise it hugs its label', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 300,
          child: Column(
            children: [
              AppButton.primary('Continue', expanded: true, onPressed: () {}),
              AppButton.text('Later', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    expect(tester.getSize(_pill('Continue')).width, 300);
    expect(tester.getSize(_pill('Later')).width, lessThan(150));
  });

  testWidgets('at twice the font size a long label wraps in a narrow row '
      'instead of overflowing', (tester) async {
    tester.view
      ..devicePixelRatio = 2
      ..physicalSize = const Size(360, 640) * 2;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      _app(
        Row(
          children: [
            Expanded(
              child: AppButton.primary(
                'Turn on artist photos and biographies',
                icon: AppIcons.play,
                onPressed: () {},
              ),
            ),
            Expanded(
              child: AppButton.secondary(
                'Shuffle',
                icon: AppIcons.shuffle,
                expanded: true,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(_pill('Turn on artist photos and biographies')).height,
      greaterThan(44),
    );
  });
}
