import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/app_dialog.dart';

Widget _app(Widget Function(BuildContext) home) => MaterialApp(
  theme: AppTheme.dark,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Builder(builder: home)),
);

void main() {
  /// Opens a confirmation and returns a reader of its result.
  Future<bool? Function()> openConfirm(
    WidgetTester tester, {
    bool destructive = false,
  }) async {
    bool? result;
    await tester.pumpWidget(
      _app(
        (context) => TextButton(
          onPressed: () async => result = await showConfirmDialog(
            context,
            title: 'Delete playlist?',
            body: 'It cannot be undone.',
            confirmLabel: 'Delete',
            destructive: destructive,
          ),
          child: const Text('Open'),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return () => result;
  }

  testWidgets('confirm returns true, cancel and a tap outside false', (
    tester,
  ) async {
    var result = await openConfirm(tester);
    expect(find.text('Delete playlist?'), findsOneWidget);
    expect(find.text('It cannot be undone.'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(result(), isTrue);
    expect(find.text('Delete playlist?'), findsNothing);

    result = await openConfirm(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result(), isFalse);

    result = await openConfirm(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(result(), isFalse);
    expect(find.text('Delete playlist?'), findsNothing);
  });

  testWidgets('a destructive confirmation is in the error colour', (
    tester,
  ) async {
    await openConfirm(tester, destructive: true);
    final style = tester
        .widget<TextButton>(find.widgetWithText(TextButton, 'Delete'))
        .style!;
    expect(style.foregroundColor!.resolve({}), AppTheme.dark.colorScheme.error);
  });

  testWidgets('fades in while growing to full size, and back out', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        (context) => TextButton(
          onPressed: () => showMessageDialog(context, title: 'Hi', body: 'B'),
          child: const Text('Open'),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(kDialogTransitionDuration ~/ 2);

    double opacity() => tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: find.byType(AlertDialog),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;
    double scale() => tester
        .widget<ScaleTransition>(
          find.ancestor(
            of: find.byType(AlertDialog),
            matching: find.byType(ScaleTransition),
          ),
        )
        .scale
        .value;

    expect(opacity(), inExclusiveRange(0, 1));
    expect(scale(), inExclusiveRange(.92, 1));

    await tester.pumpAndSettle();
    expect(opacity(), 1);
    expect(scale(), 1);

    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(kDialogTransitionDuration ~/ 2);
    expect(opacity(), inExclusiveRange(0, 1));
    expect(scale(), lessThan(1));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('only fades when animations are reduced', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _app(
          (context) => TextButton(
            onPressed: () => showMessageDialog(context, title: 'Hi', body: 'B'),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(kDialogTransitionDuration ~/ 2);

    expect(
      find.ancestor(
        of: find.byType(AlertDialog),
        matching: find.byType(ScaleTransition),
      ),
      findsNothing,
    );
    await tester.pumpAndSettle();
    expect(find.text('Hi'), findsOneWidget);
  });

  testWidgets('the text prompt returns the trimmed text; blank keeps '
      'the confirm button disabled', (tester) async {
    String? result = 'untouched';
    await tester.pumpWidget(
      _app(
        (context) => TextButton(
          onPressed: () async => result = await showTextInputDialog(
            context,
            title: 'New playlist',
            placeholder: 'Name',
            confirmLabel: 'Create',
          ),
          child: const Text('Open'),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    TextButton create() =>
        tester.widget<TextButton>(find.widgetWithText(TextButton, 'Create'));
    expect(create().onPressed, isNull);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(create().onPressed, isNull);

    await tester.enterText(find.byType(TextField), '  Road trip  ');
    await tester.pump();
    // No "0/80" counter under the field.
    expect(find.textContaining('/80'), findsNothing);
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(result, 'Road trip');
  });

  testWidgets('on a small screen at twice the font size, with the keyboard '
      'up, the field keeps its height and a long body scrolls', (tester) async {
    tester.view
      ..devicePixelRatio = 2
      ..physicalSize = const Size(360, 640) * 2
      ..viewInsets = const FakeViewPadding(bottom: 280 * 2);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      _app(
        (context) => Column(
          children: [
            TextButton(
              onPressed: () => showTextInputDialog(
                context,
                title: 'New playlist',
                placeholder: 'Name',
                confirmLabel: 'Create',
              ),
              child: const Text('Prompt'),
            ),
            TextButton(
              onPressed: () => showConfirmDialog(
                context,
                title: 'Reset everything?',
                body: List.filled(30, 'Long explanation.').join(' '),
                confirmLabel: 'Reset',
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Prompt'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(TextField)).height, greaterThan(40));
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final scrollable = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsWidgets);
    await tester.scrollUntilVisible(
      find.textContaining('Long explanation.'),
      100,
      scrollable: scrollable.first,
    );
  });
}
