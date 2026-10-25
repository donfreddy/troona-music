import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/features/settings/presentation/widgets/settings_section_header.dart';
import 'package:troona/features/settings/presentation/widgets/segmented_row.dart';

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
          const SliverAppBar.large(
            title: Text('Settings'),
            floating: true,
            snap: true,
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              // Playback
              SettingsSectionHeader('Playback'),
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

              // Interface
              SettingsSectionHeader('Interface'),
              SwitchListTile(
                title: const Text('Haptic feedback'),
                value: settings.hapticFeedbackEnabled,
                onChanged: cubit.setHapticFeedback,
              ),
              SegmentedRow<GlassQuality>(
                label: 'Glass quality',
                values: GlassQuality.values,
                labels: const ['Auto', 'High', 'Low', 'Off'],
                selected: settings.glassQuality,
                onChanged: cubit.setGlassQuality,
              ),

              // Reset
              SettingsSectionHeader('Reset'),
              ListTile(
                leading: const Icon(Icons.music_off_outlined),
                title: const Text('Clear playback session'),
                subtitle: const Text(
                  'Forget the current track, queue, and saved position.',
                ),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Clear playback session?'),
                      content: const Text(
                        'The app will forget the last restored track, queue, and playback position.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true || !context.mounted) return;
                  await cubit.clearPlaybackSession();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playback session cleared')),
                  );
                },
              ),
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

              const SizedBox(height: 80),
            ]),
          ),
        ],
      ),
    );
  }
}
