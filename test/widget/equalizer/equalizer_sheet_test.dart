import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/equalizer/data/repositories/prefs_equalizer_repository.dart';
import 'package:troona/features/equalizer/domain/entities/eq_layout.dart';
import 'package:troona/features/equalizer/domain/entities/equalizer_settings.dart';
import 'package:troona/features/equalizer/presentation/cubit/equalizer_cubit.dart';
import 'package:troona/features/equalizer/presentation/widgets/equalizer_sheet.dart';
import 'package:troona/l10n/app_localizations.dart';

import '../../helpers/fake_equalizer.dart';
import '../../helpers/roboto.dart';

void main() {
  late FakeEqualizerPort port;
  late EqualizerCubit cubit;
  var ids = 0;

  /// A started cubit, with [layout] known (none: no song loaded yet).
  Future<void> setUpCubit({EqLayout? layout, bool enabled = true}) async {
    SharedPreferences.setMockInitialValues({});
    final repo = PrefsEqualizerRepository(
      await SharedPreferences.getInstance(),
    );
    if (layout != null) await repo.saveLayout(layout);
    await repo.saveSettings(EqualizerSettings(enabled: enabled));
    port = FakeEqualizerPort();
    ids = 0;
    cubit = EqualizerCubit(
      port: port,
      repo: repo,
      transitionSteps: 1,
      newId: () => 'p${ids++}',
    )..start();
  }

  /// The sheet opened from a button, as the dock and Settings open it.
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<EqualizerCubit>.value(
        value: cubit,
        child: MaterialApp(
          theme: robotoTheme(AppTheme.dark),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showEqualizerSheet(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  tearDown(() => cubit.close());

  testWidgets('before a song loads: the empty state, and nothing to save', (
    tester,
  ) async {
    await setUpCubit();
    await open(tester);

    expect(
      find.textContaining('Play a song to tune the equalizer'),
      findsOneWidget,
    );
    // No layout, no band count.
    expect(find.textContaining('bands on this phone'), findsNothing);
    // The Save chip takes no tap: tapping it opens no dialog.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Save this curve'), findsNothing);
  });

  testWidgets('off: the hint shows and the presets take no tap; the switch '
      'turns it on', (tester) async {
    await setUpCubit(layout: fiveBands, enabled: false);
    await open(tester);

    expect(find.text('Turn the equalizer on to tune it.'), findsOneWidget);
    // Out of reach: the hit test stops at the dimmed row.
    await tester.tap(find.text('Acoustic'), warnIfMissed: false);
    await tester.pump();
    expect(cubit.state.settings.presetId, isNot('acoustic'));

    await tester.tap(find.byType(CupertinoSwitch).first);
    await tester.pumpAndSettle();
    expect(cubit.state.settings.enabled, isTrue);
    expect(port.outputs.last.enabled, isTrue);
    expect(find.text('Turn the equalizer on to tune it.'), findsNothing);
  });

  testWidgets('a preset tapped is selected and sent', (tester) async {
    await setUpCubit(layout: fiveBands);
    await open(tester);

    await tester.tap(find.text('Acoustic'));
    await tester.pumpAndSettle();
    expect(cubit.state.settings.presetId, 'acoustic');
    expect(port.outputs.last.gains, cubit.state.gains);
    expect(port.outputs.last.gains.any((g) => g != 0), isTrue);
  });

  testWidgets('a curve of its own shows Custom and saves as a profile', (
    tester,
  ) async {
    await setUpCubit(layout: fiveBands);
    await open(tester);
    expect(find.text('Custom'), findsNothing);

    cubit.setBand(0, 6);
    await tester.pumpAndSettle();
    expect(find.text('Custom'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Save this curve'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Car');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    expect(cubit.state.profiles.single.name, 'Car');
    expect(cubit.state.currentProfile?.name, 'Car');
    // The chip shows, selected, and Custom goes: the curve has a name.
    expect(find.text('Car'), findsOneWidget);
    expect(find.text('Custom'), findsNothing);
  });

  for (final (name, layout) in [('5', fiveBands), ('10', tenBands)]) {
    for (final scale in [1.3, 2.0]) {
      testWidgets('360 x 640, $name bands, text x$scale: nothing overflows', (
        tester,
      ) async {
        await loadRoboto();
        tester.view
          ..devicePixelRatio = 3
          ..physicalSize = const Size(360, 640) * 3;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await setUpCubit(layout: layout);
        cubit.setBand(0, 6);
        await open(tester);

        expect(tester.takeException(), isNull);
        expect(find.byType(EqualizerSheet), findsOneWidget);
        // The tools are reachable by scrolling.
        await tester.scrollUntilVisible(
          find.text('Avoid clipping'),
          100,
          scrollable: find
              .descendant(
                of: find.byType(EqualizerSheet),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  group('eqSummary, the Settings row value', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    test('off, a preset, Custom, then a profile', () async {
      await setUpCubit(layout: fiveBands, enabled: false);
      expect(eqSummary(l10n, cubit.state), 'Off');

      cubit
        ..setEnabled(true)
        ..selectPreset('rock');
      expect(eqSummary(l10n, cubit.state), 'Rock');

      cubit.setBand(0, -7);
      expect(eqSummary(l10n, cubit.state), 'Custom');

      cubit.saveProfile('Car');
      expect(eqSummary(l10n, cubit.state), 'Car');
    });
  });
}
