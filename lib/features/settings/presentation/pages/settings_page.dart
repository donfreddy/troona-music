import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/theme/components/glass_theme.dart'
    hide GlassQuality;
import 'package:troona/core/theme/glass_tier.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/crash_log.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/features/settings/presentation/widgets/segmented_row.dart';
import 'package:troona/services/scanner/artwork_extractor.dart';
import 'package:troona/shared/widgets/glass_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        if (state is SettingsLoading) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is SettingsError) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: Text(state.message)),
          );
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

  Future<void> _clearArtworkCache(BuildContext context) async {
    try {
      await getIt<IsarLibraryDataSource>().clearAllArtworkPaths();

      final dir = getIt<ArtworkExtractor>().cacheDir;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }

      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      if (context.mounted) {
        context.read<LibraryBloc>().add(const LibraryRefreshRequested());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Artwork cache cleared. Re-scanning library...'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing artwork cache: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _copyDiagnostics(BuildContext context) async {
    final tier = GlassTier.detected.name;
    final quality = GlassTheme.resolveQuality(context).name;
    final libState = context.read<LibraryBloc>().state;
    final trackCount = libState is LibraryLoaded ? libState.totalCount : 'N/A';

    final deviceInfo = DeviceInfoPlugin();
    String deviceStr = Platform.operatingSystem;
    try {
      if (Platform.isAndroid) {
        final a = await deviceInfo.androidInfo;
        deviceStr =
            '${a.manufacturer} ${a.model} (Android ${a.version.release}, SDK ${a.version.sdkInt})';
      } else if (Platform.isIOS) {
        final i = await deviceInfo.iosInfo;
        deviceStr = '${i.utsname.machine} (iOS ${i.systemVersion})';
      }
    } catch (_) {}

    final logFile = CrashLog.logFile;
    final logExists = logFile != null && await logFile.exists();

    final diagnostics =
        '''
=== Troona Music Diagnostics ===
App Version: 1.0.0+1
Device: $deviceStr
GPU / Glass Tier: $tier (Effective Quality: $quality)
Total Indexed Tracks: $trackCount
Haptics Enabled: ${AppHaptics.enabled}
Crash Log File: ${logFile?.path ?? 'None'}
Crash Log Exists: $logExists
Timestamp: ${DateTime.now().toIso8601String()}
================================
''';

    await Clipboard.setData(ClipboardData(text: diagnostics));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diagnostics copied to clipboard'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showCrashLogsDialog(BuildContext context) async {
    final logs = await CrashLog.readRecentLogs(limit: 60);
    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recent Crash & Error Logs'),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: logs.isEmpty
              ? const Center(child: Text('No crash logs recorded.'))
              : SingleChildScrollView(
                  child: SelectableText(
                    logs.join('\n'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
        ),
        actions: [
          if (logs.isNotEmpty)
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: logs.join('\n')));
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logs copied to clipboard'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Copy All'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        children: [
          // Playback
          _SettingsGroup(
            title: 'Playback',
            children: [
              SwitchListTile(
                secondary: const Icon(LucideIcons.phoneOff),
                title: const Text('Pause on incoming call'),
                value: settings.stopOnCallEnabled,
                onChanged: cubit.setStopOnCall,
              ),
              SwitchListTile(
                secondary: const Icon(LucideIcons.phoneCall),
                title: const Text('Resume after call'),
                value: settings.resumeAfterCallEnabled,
                onChanged: cubit.setResumeAfterCall,
              ),
              SwitchListTile(
                secondary: const Icon(LucideIcons.volume2),
                title: const Text('Duck audio on notification'),
                value: settings.duckAudioOnNotification,
                onChanged: cubit.setDuckAudioOnNotification,
              ),
            ],
          ),

          // Interface
          _SettingsGroup(
            title: 'Interface',
            children: [
              SwitchListTile(
                secondary: const Icon(LucideIcons.vibrate),
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
            ],
          ),

          // Library & Maintenance
          _SettingsGroup(
            title: 'Library & Maintenance',
            children: [
              BlocBuilder<LibraryBloc, LibraryState>(
                buildWhen: (p, c) =>
                    (p is LibraryScanning) != (c is LibraryScanning),
                builder: (context, state) {
                  final scanning = state is LibraryScanning;
                  return ListTile(
                    leading: const Icon(LucideIcons.refreshCw),
                    title: const Text('Rescan library'),
                    subtitle: Text(
                      scanning
                          ? 'Scanning files...'
                          : 'Refresh all local tracks and albums',
                    ),
                    trailing: scanning
                        ? const CupertinoActivityIndicator()
                        : null,
                    onTap: scanning
                        ? null
                        : () {
                            context.read<LibraryBloc>().add(
                              const LibraryRefreshRequested(),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Library scan started'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                  );
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.imageOff),
                title: const Text('Clear artwork cache'),
                subtitle: const Text(
                  'Delete cached cover art and re-extract on demand',
                ),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Clear artwork cache?'),
                      content: const Text(
                        'All cached album art will be deleted from disk and re-scanned.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true || !context.mounted) return;
                  await _clearArtworkCache(context);
                },
              ),
            ],
          ),

          // Reset
          _SettingsGroup(
            title: 'Reset',
            children: [
              ListTile(
                leading: const Icon(LucideIcons.music2),
                title: const Text('Clear playback session'),
                subtitle: const Text(
                  'Forget the current track, queue, and saved position.',
                ),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Clear playback session?'),
                      content: const Text(
                        'The app will forget the last restored track, queue, and playback position.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true || !context.mounted) return;
                  await cubit.clearPlaybackSession();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Playback session cleared'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.rotateCcw),
                title: const Text('Reset to defaults'),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Reset settings?'),
                      content: const Text(
                        'All preferences will be restored to their default values.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) cubit.resetToDefaults();
                },
              ),
            ],
          ),

          // About & Diagnostics
          _SettingsGroup(
            title: 'About & Diagnostics',
            children: [
              ListTile(
                leading: const Icon(LucideIcons.clipboardList),
                title: const Text('Copy diagnostics'),
                subtitle: const Text(
                  'Copy system, audio engine, and memory info',
                ),
                onTap: () => _copyDiagnostics(context),
              ),
              ListTile(
                leading: const Icon(LucideIcons.bug),
                title: const Text('Crash logs'),
                subtitle: const Text('View recent app crash and error logs'),
                onTap: () => _showCrashLogsDialog(context),
              ),
            ],
          ),

          SizedBox(
            height:
                AppSpacing.miniPlayerHeight +
                MediaQuery.of(context).padding.bottom +
                AppSpacing.xl,
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: colors.accent,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: GlassCard(
            config: GlassTheme.card(
              context,
            ).copyWith(blurSigma: 0, padding: EdgeInsets.zero),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 16,
                      endIndent: 16,
                      color: colors.separator.withValues(alpha: 0.2),
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
