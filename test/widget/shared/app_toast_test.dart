import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/shared/widgets/app_toast.dart';

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
}
