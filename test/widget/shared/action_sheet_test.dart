import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/components/blur_budget.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/action_sheet.dart';
import 'package:troona/shared/widgets/glass_bottom_sheet.dart';

Widget _app(Widget Function(BuildContext) home, {bool spent = false}) =>
    MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: spent
            ? BlurBudgetSpent(child: Builder(builder: home))
            : Builder(builder: home),
      ),
    );

/// A button that opens an action sheet with [actions].
Widget _opener(List<SheetAction> actions, {bool spent = false}) => _app(
  (context) => TextButton(
    onPressed: () => showActionSheet(
      context,
      title: 'Song',
      message: 'Artist',
      actions: actions,
    ),
    child: const Text('Open'),
  ),
  spent: spent,
);

Finder get _sheetBlur => find.descendant(
  of: find.byType(GlassBottomSheet),
  matching: find.byType(BackdropFilter),
);

void main() {
  tearDown(() {
    GlassTheme.setDetectedTier(GlassQuality.high);
    GlassTheme.overrideQuality(null);
  });

  testWidgets('shows the title, the message and the actions; a tap closes '
      'the sheet, then runs the action', (tester) async {
    var sheetOpenWhenRun = true;
    await tester.pumpWidget(
      _opener([
        SheetAction(label: 'Play next', onPressed: () {}),
        SheetAction(
          label: 'Delete',
          destructive: true,
          onPressed: () {
            final route = ModalRoute.of(tester.element(find.text('Open')));
            sheetOpenWhenRun = !(route?.isCurrent ?? false);
          },
        ),
      ]),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Song'), findsOneWidget);
    expect(find.text('Artist'), findsOneWidget);
    expect(find.text('Play next'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(sheetOpenWhenRun, isFalse);
    expect(find.text('Song'), findsNothing);
  });

  testWidgets('a selected action is in the accent colour with a check; a '
      'destructive one is in the error colour', (tester) async {
    await tester.pumpWidget(
      _opener([
        SheetAction(label: 'Title', selected: true, onPressed: () {}),
        SheetAction(label: 'Artist name', onPressed: () {}),
        SheetAction(label: 'Delete', destructive: true, onPressed: () {}),
      ]),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final theme = AppTheme.dark;
    Color? colorOf(String label) =>
        tester.widget<Text>(find.text(label)).style?.color;
    expect(colorOf('Title'), theme.colorScheme.primary);
    expect(colorOf('Delete'), theme.colorScheme.error);
    expect(colorOf('Artist name'), isNot(theme.colorScheme.primary));
    expect(find.byIcon(AppIcons.selected), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Title')),
      isSemantics(isSelected: true, isButton: true),
    );
  });

  testWidgets('glass on a high-tier device, opaque on a low-tier one', (
    tester,
  ) async {
    final actions = [SheetAction(label: 'Play next', onPressed: () {})];
    await tester.pumpWidget(_opener(actions));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(_sheetBlur, findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    GlassTheme.setDetectedTier(GlassQuality.low);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(GlassBottomSheet), findsOneWidget);
    expect(_sheetBlur, findsNothing);
  });

  testWidgets('opaque when opened below a spent blur budget (Now Playing)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _opener([SheetAction(label: 'Play next', onPressed: () {})], spent: true),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(GlassBottomSheet), findsOneWidget);
    expect(_sheetBlur, findsNothing);
  });

  testWidgets('a sheet opened from a sheet is opaque', (tester) async {
    await tester.pumpWidget(
      _app(
        (context) => TextButton(
          onPressed: () => showGlassBottomSheet<void>(
            context: context,
            builder: (sheetContext) => TextButton(
              onPressed: () => showActionSheet(
                sheetContext,
                actions: [SheetAction(label: 'Inner', onPressed: () {})],
              ),
              child: const Text('Nested'),
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nested'));
    await tester.pumpAndSettle();

    expect(find.byType(GlassBottomSheet), findsNWidgets(2));
    // Only the outer sheet blurs.
    expect(_sheetBlur, findsOneWidget);
  });

  testWidgets('a long menu at twice the font size scrolls instead of '
      'overflowing, below the status bar', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 640) * 2
      ..devicePixelRatio = 2
      // A status bar: the sheet must stop below it.
      ..padding = const FakeViewPadding(top: 24 * 2);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      _opener([
        for (var i = 0; i < 12; i++)
          SheetAction(label: 'Action number $i', onPressed: () {}),
      ]),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.byType(GlassBottomSheet)).dy,
      greaterThanOrEqualTo(24),
    );
    await tester.scrollUntilVisible(
      find.text('Action number 11'),
      100,
      scrollable: find.descendant(
        of: find.byType(GlassBottomSheet),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Action number 11').hitTestable(), findsOneWidget);
  });
}
