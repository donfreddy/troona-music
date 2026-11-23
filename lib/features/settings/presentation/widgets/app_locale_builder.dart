import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';

/// Hands down the app's locale from the language setting in [settings]:
/// null, the phone's languages, until it is read or when it says so.
class AppLocaleBuilder extends StatelessWidget {
  final SettingsCubit settings;
  final Widget Function(BuildContext context, Locale? locale) builder;

  const AppLocaleBuilder({
    super.key,
    required this.settings,
    required this.builder,
  });

  /// The language setting in [state], the phone's until settings are read.
  static AppLanguage languageOf(SettingsState state) =>
      state.mapOrNull(loaded: (s) => s.settings.language) ?? AppLanguage.system;

  static Locale? localeOf(AppLanguage language) => switch (language.code) {
    final code? => Locale(code),
    null => null,
  };

  @override
  Widget build(BuildContext context) =>
      BlocSelector<SettingsCubit, SettingsState, AppLanguage>(
        bloc: settings,
        selector: languageOf,
        builder: (context, language) => builder(context, localeOf(language)),
      );
}
