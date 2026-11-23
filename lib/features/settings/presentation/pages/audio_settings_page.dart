import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/equalizer/presentation/cubit/equalizer_cubit.dart';
import 'package:troona/features/equalizer/presentation/widgets/equalizer_sheet.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/features/settings/presentation/widgets/settings_hue.dart';
import 'package:troona/features/settings/presentation/widgets/settings_builder.dart';
import 'package:troona/features/settings/presentation/widgets/settings_section.dart';
import 'package:troona/features/settings/presentation/widgets/settings_subpage.dart';
import 'package:troona/features/settings/presentation/widgets/settings_tile.dart';

/// The equalizer, and what playback does when another sound needs the
/// speaker.
class AudioSettingsPage extends StatelessWidget {
  const AudioSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SettingsCubit>();
    // Supported or not is decided at start-up: a row that comes and goes
    // would leave its divider behind.
    final equalizer = switch (context.read<EqualizerCubit?>()) {
      final eq? when eq.state.supported => eq,
      _ => null,
    };
    return SettingsSubpage(
      title: l10n.settingsAudio,
      intro: l10n.settingsAudioIntro,
      children: [
        if (equalizer != null)
          SettingsSection(
            title: l10n.settingsSound,
            children: [
              BlocBuilder<EqualizerCubit, EqualizerState>(
                bloc: equalizer,
                builder: (context, eq) => SettingsTile.navigation(
                  icon: AppIcons.equalizer,
                  iconColor: SettingsHue.audio,
                  title: l10n.equalizerTitle,
                  value: eqSummary(l10n, eq),
                  onTap: () => showEqualizerSheet(context),
                ),
              ),
            ],
          ),
        SettingsBuilder(
          builder: (context, settings) => SettingsSection(
            title: l10n.settingsInterruptions,
            footer: l10n.settingsAudioFooter,
            children: [
              SettingsTile.switchTile(
                icon: AppIcons.volumeLow,
                iconColor: SettingsHue.audio,
                title: l10n.settingsDuck,
                subtitle: l10n.settingsDuckSubtitle,
                value: settings.duckAudioOnNotification,
                onChanged: cubit.setDuckAudioOnNotification,
              ),
              SettingsTile.switchTile(
                icon: AppIcons.pauseOnCall,
                iconColor: SettingsHue.audio,
                title: l10n.settingsPauseOnCall,
                subtitle: l10n.settingsPauseOnCallSubtitle,
                value: settings.stopOnCallEnabled,
                onChanged: cubit.setStopOnCall,
              ),
              // Nothing to resume when nothing was paused.
              SettingsTile.switchTile(
                icon: AppIcons.resumeAfterCall,
                iconColor: SettingsHue.audio,
                title: l10n.settingsResumeAfterCall,
                subtitle: l10n.settingsResumeAfterCallSubtitle,
                value: settings.resumeAfterCallEnabled,
                enabled: settings.stopOnCallEnabled,
                onChanged: cubit.setResumeAfterCall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
