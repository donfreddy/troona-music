import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/glass_tier.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
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

/// Glass effects and haptics.
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
