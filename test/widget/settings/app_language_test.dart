import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/features/settings/presentation/widgets/app_locale_builder.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/services/audio/audio_service_initializer.dart';

void main() {
  late SettingsCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cubit = SettingsCubit(
      SettingsRepositoryImpl(await SharedPreferences.getInstance()),
    );
    await cubit.load();
  });

  tearDown(() => cubit.close());

  /// The app as main.dart builds it, the phone set to English.
  Widget app() => AppLocaleBuilder(
    settings: cubit,
    builder: (context, locale) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) =>
            Text(AppLocalizations.of(context).settingsLanguage),
      ),
    ),
  );

  testWidgets('the app speaks the language chosen, then the phone\'s again', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(app());
    expect(find.text('Language'), findsOneWidget);

    await cubit.setLanguage(AppLanguage.fr);
    await tester.pumpAndSettle();
    expect(find.text('Langue'), findsOneWidget);

    await cubit.setLanguage(AppLanguage.system);
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
  });

  test('strings outside the app follow the language chosen', () {
    const phone = [Locale('en', 'US')];
    expect(
      AudioServiceInitializer.localesFor(AppLanguage.system, phone),
      phone,
    );
    expect(AudioServiceInitializer.localesFor(AppLanguage.fr, phone), const [
      Locale('fr'),
    ]);
    expect(
      AudioServiceInitializer.channelName(
        AudioServiceInitializer.localesFor(AppLanguage.fr, phone),
      ),
      lookupAppLocalizations(const Locale('fr')).notificationChannelName,
    );
  });
}
