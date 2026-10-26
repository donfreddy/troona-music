import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/shared/widgets/app_toast.dart';
import 'package:troona/shared/widgets/toast_anchor.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('showOn still shows after the calling route closed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (sheet) => TextButton(
                onPressed: () {
                  final overlay = Overlay.of(sheet, rootOverlay: true);
                  Navigator.pop(sheet);
                  AppToast.showOn(overlay, 'Added');
                },
                child: const Text('Add'),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Add'), findsNothing);
    expect(find.text('Added'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Added'), findsNothing);
  });

  group('position', () {
    const screen = Size(400, 800);

    /// A page with a bottom bar of [barHeight] (0 renders nothing), laid out
    /// as the shell does: 12 px above the bottom edge.
    Widget page(ValueNotifier<double> barHeight, {bool anchored = true}) =>
        MaterialApp(
          theme: AppTheme.dark,
          home: Stack(
            children: [
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: ValueListenableBuilder<double>(
                  valueListenable: barHeight,
                  builder: (_, h, _) {
                    final bar = SizedBox(height: h);
                    return anchored ? ToastAnchor(child: bar) : bar;
                  },
                ),
              ),
              Builder(
                builder: (context) => Center(
                  child: TextButton(
                    onPressed: () => AppToast.show(context, 'Saved'),
                    child: const Text('Show'),
                  ),
                ),
              ),
            ],
          ),
        );

    Future<double> toastBottom(WidgetTester tester) async {
      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      return tester.getRect(find.byType(AnimatedPositioned)).bottom;
    }

    Future<void> setScreen(WidgetTester tester) async {
      tester.view.physicalSize = screen;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    for (final (label, height) in [
      ('mini player and tabs', 134.0),
      ('mini player only', 64.0),
      ('tabs only', 64.0),
    ]) {
      testWidgets('just above the bar: $label', (tester) async {
        await setScreen(tester);
        await tester.pumpWidget(page(ValueNotifier(height)));
        await tester.pump();

        final barTop = screen.height - 12 - height;
        expect(await toastBottom(tester), barTop - AppToast.gap);
        AppToast.dismiss();
      });
    }

    testWidgets('no bar content: near the bottom edge', (tester) async {
      await setScreen(tester);
      await tester.pumpWidget(page(ValueNotifier(0)));
      await tester.pump();

      expect(await toastBottom(tester), screen.height - 12 - AppToast.gap);
      AppToast.dismiss();
    });

    testWidgets('no bar at all: near the bottom edge', (tester) async {
      await setScreen(tester);
      await tester.pumpWidget(page(ValueNotifier(134), anchored: false));
      await tester.pump();

      expect(await toastBottom(tester), screen.height - 12 - AppToast.gap);
      AppToast.dismiss();
    });

    testWidgets('follows the bar while shown', (tester) async {
      await setScreen(tester);
      final height = ValueNotifier<double>(64);
      await tester.pumpWidget(page(height));
      await tester.pump();
      await toastBottom(tester);

      height.value = 134; // the tabs come back
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        tester.getRect(find.byType(AnimatedPositioned)).bottom,
        screen.height - 12 - 134 - AppToast.gap,
      );
      AppToast.dismiss();
    });
  });
}
