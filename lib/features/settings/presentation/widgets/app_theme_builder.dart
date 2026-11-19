import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/components/glass_settings.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';

/// Builds the app's theme from the glass quality setting in [settings],
/// "auto" drawing with the tier [detected] on the device: changing the
/// setting rebuilds every glass surface ([GlassSettings]).
class AppThemeBuilder extends StatelessWidget {
  final SettingsCubit settings;
  final GlassQuality detected;
  final Widget Function(BuildContext context, ThemeData theme) builder;

  const AppThemeBuilder({
    super.key,
    required this.settings,
    required this.detected,
    required this.builder,
  });

  /// The glass quality setting in [state], auto until settings are read.
  static GlassQuality settingOf(SettingsState state) =>
      state.mapOrNull(loaded: (s) => s.settings.glassQuality) ??
      GlassQuality.auto;

  @override
  Widget build(BuildContext context) =>
      BlocSelector<SettingsCubit, SettingsState, GlassQuality>(
        bloc: settings,
        selector: settingOf,
        builder: (context, setting) => builder(
          context,
          AppTheme.withGlass(GlassSettings.effective(setting, detected)),
        ),
      );
}
