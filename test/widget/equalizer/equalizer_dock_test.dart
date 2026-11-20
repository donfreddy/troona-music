import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/equalizer/data/repositories/prefs_equalizer_repository.dart';
import 'package:troona/features/equalizer/presentation/cubit/equalizer_cubit.dart';
import 'package:troona/features/equalizer/presentation/widgets/equalizer_sheet.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/bloc/sleep_timer/sleep_timer_cubit.dart';
import 'package:troona/features/player/presentation/widgets/player_utility_dock.dart';
import 'package:troona/l10n/app_localizations.dart';

import '../../helpers/fake_equalizer.dart';
import '../../helpers/fake_player.dart';

void main() {
  /// The dock, with an equalizer whose port is [supported], or none.
  Future<EqualizerCubit?> pumpDock(
    WidgetTester tester, {
    bool? supported,
  }) async {
    final (:player, :port) = await testPlayer(addTearDown);
    final timer = SleepTimerCubit(port: port);
    addTearDown(timer.close);
    EqualizerCubit? equalizer;
    if (supported != null) {
      final repo = PrefsEqualizerRepository(
        await SharedPreferences.getInstance(),
      );
      await repo.saveLayout(fiveBands);
      equalizer = EqualizerCubit(
        port: FakeEqualizerPort(supported: supported),
        repo: repo,
      )..start();
      addTearDown(equalizer.close);
    }
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<PlayerBloc>.value(value: player),
          BlocProvider<SleepTimerCubit>.value(value: timer),
          if (equalizer != null)
            BlocProvider<EqualizerCubit>.value(value: equalizer),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: Center(child: PlayerUtilityDock())),
        ),
      ),
    );
    return equalizer;
  }

  Color? iconColor(WidgetTester tester) =>
      tester.widget<Icon>(find.byIcon(AppIcons.equalizer)).color;

  testWidgets('no equalizer provided: three items, no fourth', (tester) async {
    await pumpDock(tester);
    expect(find.byIcon(AppIcons.equalizer), findsNothing);
    expect(find.byIcon(AppIcons.queue), findsOneWidget);
  });

  testWidgets('a phone without the effects: no item', (tester) async {
    await pumpDock(tester, supported: false);
    expect(find.byIcon(AppIcons.equalizer), findsNothing);
  });

  testWidgets('supported: the item follows the switch and opens the sheet', (
    tester,
  ) async {
    final equalizer = (await pumpDock(tester, supported: true))!;
    final accent = tester.element(find.byType(PlayerUtilityDock)).colors.accent;
    expect(find.byIcon(AppIcons.equalizer), findsOneWidget);
    expect(iconColor(tester), isNot(accent));

    equalizer.setEnabled(true);
    await tester.pump();
    expect(iconColor(tester), accent);

    await tester.tap(find.byIcon(AppIcons.equalizer));
    await tester.pumpAndSettle();
    expect(find.byType(EqualizerSheet), findsOneWidget);
  });
}
