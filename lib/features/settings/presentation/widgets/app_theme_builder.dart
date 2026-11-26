import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/components/ambient_glow.dart';
import 'package:troona/core/theme/components/glass_settings.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';

/// Builds the app's theme from the appearance settings in [settings]:
/// the glass quality, "auto" drawing with the tier [detected] on the
/// device, the accent and the black background. Changing one rebuilds
/// every surface that reads it ([GlassSettings], [AppColors],
/// [AmbientGlow]).
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

  /// The settings the theme is built from, the defaults until read.
  static ({GlassQuality glass, AppAccent accent, bool black}) appearanceOf(
    SettingsState state,
  ) {
    final s = state.mapOrNull(loaded: (s) => s.settings) ?? const AppSettings();
    return (glass: s.glassQuality, accent: s.accent, black: s.blackBackground);
  }

  @override
  Widget build(BuildContext context) =>
      BlocSelector<
        SettingsCubit,
        SettingsState,
        ({GlassQuality glass, AppAccent accent, bool black})
      >(
        bloc: settings,
        selector: appearanceOf,
        builder: (context, appearance) => builder(
          context,
          AppTheme.withGlass(
            GlassSettings.effective(appearance.glass, detected),
            accent: appearance.accent,
            ambientGlow: !appearance.black,
          ),
        ),
      );
}
