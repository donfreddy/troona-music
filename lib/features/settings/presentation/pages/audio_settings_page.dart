import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/equalizer/presentation/cubit/equalizer_cubit.dart';
import 'package:troona/features/equalizer/presentation/widgets/equalizer_sheet.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/features/settings/presentation/widgets/segmented_row.dart';
import 'package:troona/features/settings/presentation/widgets/settings_builder.dart';
import 'package:troona/features/settings/presentation/widgets/settings_hue.dart';
import 'package:troona/features/settings/presentation/widgets/settings_section.dart';
import 'package:troona/features/settings/presentation/widgets/settings_subpage.dart';
import 'package:troona/features/settings/presentation/widgets/settings_tile.dart';

/// The equalizer, whether a new list keeps shuffle and the lyrics keep the
/// screen on, how songs lead into each other, and what playback does when
/// another sound needs the speaker.
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
            title: l10n.settingsListening,
            children: [
              SettingsTile.switchTile(
                icon: AppIcons.keepShuffle,
                iconColor: SettingsHue.audio,
                title: l10n.settingsKeepShuffle,
                subtitle: l10n.settingsKeepShuffleSubtitle,
                value: settings.keepShuffle,
                onChanged: cubit.setKeepShuffle,
              ),
              SettingsTile.switchTile(
                icon: AppIcons.lyricsScreenOn,
                iconColor: SettingsHue.audio,
                title: l10n.settingsLyricsScreenOn,
                subtitle: l10n.settingsLyricsScreenOnSubtitle,
                value: settings.lyricsKeepScreenOn,
                onChanged: cubit.setLyricsKeepScreenOn,
              ),
            ],
          ),
        ),
        SettingsBuilder(
          builder: (context, settings) => SettingsSection(
            title: l10n.settingsTransitions,
            children: [
              SettingsTile.switchTile(
                icon: AppIcons.crossfade,
                iconColor: SettingsHue.audio,
                title: l10n.settingsCrossfade,
                subtitle: l10n.settingsCrossfadeSubtitle,
                value: settings.crossfade,
                onChanged: cubit.setCrossfade,
              ),
              // Always shown, off or on: a row that comes and goes would
              // leave its divider behind.
              SegmentedRow<int>(
                label: l10n.settingsCrossfadeLength,
                subtitle: l10n.settingsCrossfadeLengthSubtitle,
                icon: AppIcons.crossfadeLength,
                iconColor: SettingsHue.audio,
                values: AppSettings.crossfadeChoices,
                labels: [
                  for (final s in AppSettings.crossfadeChoices)
                    l10n.durationSecondsShort(s),
                ],
                selected: settings.crossfadeSeconds,
                onChanged: cubit.setCrossfadeSeconds,
              ),
              SettingsTile.switchTile(
                icon: AppIcons.keepAlbumsWhole,
                iconColor: SettingsHue.audio,
                title: l10n.settingsKeepAlbumsWhole,
                subtitle: l10n.settingsKeepAlbumsWholeSubtitle,
                value: settings.keepAlbumsWhole,
                onChanged: cubit.setKeepAlbumsWhole,
              ),
            ],
          ),
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
              // Not tied to the switch above: on iOS the system pauses for
              // a call whatever it says.
              SettingsTile.switchTile(
                icon: AppIcons.resumeAfterCall,
                iconColor: SettingsHue.audio,
                title: l10n.settingsResumeAfterCall,
                subtitle: l10n.settingsResumeAfterCallSubtitle,
                value: settings.resumeAfterCallEnabled,
                onChanged: cubit.setResumeAfterCall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
