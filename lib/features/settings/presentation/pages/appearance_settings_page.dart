import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/glass_tier.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/features/settings/presentation/widgets/accent_picker.dart';
import 'package:troona/features/settings/presentation/widgets/segmented_row.dart';
import 'package:troona/features/settings/presentation/widgets/settings_builder.dart';
import 'package:troona/features/settings/presentation/widgets/settings_hue.dart';
import 'package:troona/features/settings/presentation/widgets/settings_section.dart';
import 'package:troona/features/settings/presentation/widgets/settings_subpage.dart';
import 'package:troona/features/settings/presentation/widgets/settings_tile.dart';
import 'package:troona/l10n/app_localizations.dart';

/// The name of [quality] in the glass setting.
String glassLabelOf(GlassQuality quality, AppLocalizations l10n) =>
    switch (quality) {
      GlassQuality.auto => l10n.settingsGlassAuto,
      GlassQuality.high => l10n.settingsGlassFull,
      GlassQuality.low => l10n.settingsGlassBalanced,
      GlassQuality.off => l10n.settingsGlassOff,
    };

/// The name of [language] in the language setting: each language in its
/// own words, so it can be found whatever the app shows.
String languageLabelOf(AppLanguage language, AppLocalizations l10n) =>
    switch (language) {
      AppLanguage.system => l10n.settingsLanguageSystem,
      AppLanguage.en => 'English',
      AppLanguage.fr => 'Français',
    };

/// The name of [accent] in the accent setting, for screen readers.
String accentLabelOf(AppAccent accent, AppLocalizations l10n) =>
    switch (accent) {
      AppAccent.lilac => l10n.settingsAccentLilac,
      AppAccent.blue => l10n.settingsAccentBlue,
      AppAccent.teal => l10n.settingsAccentTeal,
      AppAccent.green => l10n.settingsAccentGreen,
      AppAccent.yellow => l10n.settingsAccentYellow,
      AppAccent.orange => l10n.settingsAccentOrange,
      AppAccent.pink => l10n.settingsAccentPink,
    };

/// The app's language, colours, glass effects and haptics.
class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SettingsCubit>();
    return SettingsSubpage(
      title: l10n.settingsAppearance,
      intro: l10n.settingsAppearanceIntro,
      children: [
        SettingsBuilder(
          builder: (context, settings) => Column(
            children: [
              SettingsSection(
                title: l10n.settingsLanguage,
                children: [
                  SegmentedRow<AppLanguage>(
                    icon: AppIcons.language,
                    iconColor: SettingsHue.appearance,
                    label: l10n.settingsLanguage,
                    subtitle: l10n.settingsLanguageSubtitle,
                    values: AppLanguage.values,
                    labels: [
                      for (final language in AppLanguage.values)
                        languageLabelOf(language, l10n),
                    ],
                    selected: settings.language,
                    onChanged: cubit.setLanguage,
                  ),
                ],
              ),
              SettingsSection(
                title: l10n.settingsColors,
                children: [
                  AccentPicker(
                    icon: AppIcons.accentColor,
                    iconColor: SettingsHue.appearance,
                    label: l10n.settingsAccent,
                    subtitle: l10n.settingsAccentSubtitle,
                    selected: settings.accent,
                    nameOf: (accent) => accentLabelOf(accent, l10n),
                    onChanged: cubit.setAccent,
                  ),
                  SettingsTile.switchTile(
                    icon: AppIcons.blackBackground,
                    iconColor: SettingsHue.appearance,
                    title: l10n.settingsBlackBackground,
                    subtitle: l10n.settingsBlackBackgroundSubtitle,
                    value: settings.blackBackground,
                    onChanged: cubit.setBlackBackground,
                  ),
                ],
              ),
              SettingsSection(
                title: l10n.settingsGlass,
                footer: l10n.settingsGlassFooter(
                  glassLabelOf(GlassTier.detected, l10n),
                ),
                children: [
                  SegmentedRow<GlassQuality>(
                    icon: AppIcons.glassEffect,
                    iconColor: SettingsHue.appearance,
                    label: l10n.settingsGlass,
                    values: GlassQuality.values,
                    labels: [
                      for (final q in GlassQuality.values)
                        glassLabelOf(q, l10n),
                    ],
                    selected: settings.glassQuality,
                    onChanged: cubit.setGlassQuality,
                  ),
                ],
              ),
              SettingsSection(
                title: l10n.settingsTouch,
                children: [
                  SettingsTile.switchTile(
                    icon: AppIcons.haptics,
                    iconColor: SettingsHue.appearance,
                    title: l10n.settingsHaptics,
                    subtitle: l10n.settingsHapticsSubtitle,
                    value: settings.hapticFeedbackEnabled,
                    onChanged: cubit.setHapticFeedback,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
