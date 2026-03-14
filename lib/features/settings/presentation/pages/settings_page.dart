import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/features/settings/presentation/widgets/section_header.dart';
import 'package:troona/features/settings/presentation/widgets/segmented_row.dart';
import 'package:troona/features/settings/presentation/widgets/slider_tile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        if (state is SettingsLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is SettingsError) {
          return Scaffold(body: Center(child: Text(state.message)));
        }
        if (state is SettingsLoaded) {
          return _SettingsView(settings: state.settings);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _SettingsView extends StatelessWidget {
  final AppSettings settings;
  const _SettingsView({required this.settings});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(title: Text('Settings')),
          SliverList(
            delegate: SliverChildListDelegate([
              // Appearance
              SectionHeader('Appearance'),
              SegmentedRow<AppThemeMode>(
                label: 'Theme',
                values: AppThemeMode.values,
                labels: const ['System', 'Light', 'Dark', 'AMOLED'],
                selected: settings.themeMode,
                onChanged: cubit.setThemeMode,
              ),
              SwitchListTile(
                title: const Text('Dynamic color (Material You)'),
                value: settings.useDynamicColor,
                onChanged: cubit.setUseDynamicColor,
              ),

              // Playback
              SectionHeader('Playback'),
              SwitchListTile(
                title: const Text('Gapless playback'),
                value: settings.gaplessPlayback,
                onChanged: cubit.setGaplessPlayback,
              ),
              SwitchListTile(
                title: const Text('Crossfade'),
                subtitle: Text('${settings.crossfadeDurationMs ~/ 1000} s'),
                value: settings.crossfadeEnabled,
                onChanged: (v) => cubit.setCrossfade(enabled: v),
              ),
              if (settings.crossfadeEnabled)
                SliderTile(
                  label: 'Crossfade duration',
                  value: settings.crossfadeDurationMs.toDouble(),
                  min: 1000,
                  max: 12000,
                  divisions: 11,
                  format: (v) => '${(v / 1000).round()} s',
                  onChanged: (v) =>
                      cubit.setCrossfade(enabled: true, durationMs: v.round()),
                ),
              SwitchListTile(
                title: const Text('Pause on incoming call'),
                value: settings.stopOnCallEnabled,
                onChanged: cubit.setStopOnCall,
              ),
              SwitchListTile(
                title: const Text('Resume after call'),
                value: settings.resumeAfterCallEnabled,
                onChanged: cubit.setResumeAfterCall,
              ),
              SwitchListTile(
                title: const Text('Duck audio on notification'),
                value: settings.duckAudioOnNotification,
                onChanged: cubit.setDuckAudioOnNotification,
              ),

              // Library
              SectionHeader('Library'),
              SwitchListTile(
                title: const Text('Scan on startup'),
                value: settings.scanOnStartup,
                onChanged: cubit.setScanOnStartup,
              ),
              SwitchListTile(
                title: const Text('Watch folder changes'),
                value: settings.watchFolderChanges,
                onChanged: cubit.setWatchFolderChanges,
              ),

              // UI
              SectionHeader('Interface'),
              SwitchListTile(
                title: const Text('Haptic feedback'),
                value: settings.hapticFeedbackEnabled,
                onChanged: cubit.setHapticFeedback,
              ),
              SwitchListTile(
                title: const Text('Show album art in notification'),
                value: settings.showAlbumArtInNotification,
                onChanged: cubit.setShowAlbumArtInNotification,
              ),
              SegmentedRow<GlassQuality>(
                label: 'Glass quality',
                values: GlassQuality.values,
                labels: const ['High', 'Low', 'Off'],
                selected: settings.glassQuality,
                onChanged: cubit.setGlassQuality,
              ),

              // Sleep Timer
              SectionHeader('Sleep Timer'),
              SwitchListTile(
                title: const Text('Sleep timer'),
                subtitle: Text('${settings.sleepTimerMinutes} min'),
                value: settings.sleepTimerEnabled,
                onChanged: (v) => cubit.setSleepTimer(enabled: v),
              ),
              if (settings.sleepTimerEnabled)
                SliderTile(
                  label: 'Duration',
                  value: settings.sleepTimerMinutes.toDouble(),
                  min: 5,
                  max: 120,
                  divisions: 23,
                  format: (v) => '${v.round()} min',
                  onChanged: (v) =>
                      cubit.setSleepTimer(enabled: true, minutes: v.round()),
                ),

              // Reset
              SectionHeader('Reset'),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Reset to defaults'),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Reset settings?'),
                      content: const Text(
                        'All preferences will be restored to their default values.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) cubit.resetToDefaults();
                },
              ),

              const SizedBox(height: 80), // padding for mini player
            ]),
          ),
        ],
      ),
    );
  }
}
