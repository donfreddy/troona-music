import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/backup/domain/entities/stored_backup.dart';
import 'package:troona/features/backup/presentation/cubit/backup_cubit.dart';
import 'package:troona/features/backup/presentation/utils/backup_labels.dart';
import 'package:troona/features/settings/presentation/cubit/maintenance_cubit.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/features/settings/presentation/pages/online_settings_page.dart';
import 'package:troona/features/settings/presentation/pages/storage_settings_page.dart';
import 'package:troona/features/settings/presentation/widgets/debug_section.dart';
import 'package:troona/features/settings/presentation/widgets/settings_hue.dart';
import 'package:troona/features/settings/presentation/widgets/settings_section.dart';
import 'package:troona/features/settings/presentation/widgets/settings_tile.dart';
import 'package:troona/shared/widgets/app_back_button.dart';
import 'package:troona/shared/widgets/glass_sliver_header.dart';

/// The root of Settings: one row per category, each saying what its page
/// holds (or, where it helps, how it stands: online extras on or off, the
/// last backup, the cache's size).
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    // Once per visit, for the backup row's date and the cache's size: not
    // in the route's builder, which runs again on each change of the
    // router.
    unawaited(context.read<BackupCubit>().load());
    unawaited(context.read<MaintenanceCubit>().load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = switch (context.watch<SettingsCubit>().state) {
      SettingsLoaded(:final settings) => settings,
      _ => null,
    };
    final maintenance = context.watch<MaintenanceCubit>().state;
    final sizes = maintenance.sizes;
    final version = maintenance.version;
    final backup = context.watch<BackupCubit>().state;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          GlassSliverHeader.largeTitle(
            leading: const AppBackButton(),
            title: l10n.settingsTitle,
          ),
          SliverList.list(
            children: [
              SettingsSection(
                title: l10n.settingsPlayback,
                children: [
                  SettingsTile.navigation(
                    icon: AppIcons.settingsAudio,
                    iconColor: SettingsHue.audio,
                    title: l10n.settingsAudio,
                    subtitle: l10n.settingsAudioSummary,
                    onTap: () => context.pushNamed(AppRoute.settingsAudio),
                  ),
                ],
              ),
              SettingsSection(
                title: l10n.settingsLibrary,
                children: [
                  SettingsTile.navigation(
                    icon: AppIcons.library,
                    iconColor: SettingsHue.library,
                    title: l10n.settingsLibrary,
                    subtitle: l10n.settingsLibrarySummary,
                    onTap: () => context.pushNamed(AppRoute.settingsLibrary),
                  ),
                  SettingsTile.navigation(
                    icon: AppIcons.settingsOnline,
                    iconColor: SettingsHue.online,
                    title: l10n.settingsOnline,
                    subtitle: settings == null
                        ? null
                        : onlineSummary(l10n, settings),
                    onTap: () => context.pushNamed(AppRoute.settingsOnline),
                  ),
                ],
              ),
              SettingsSection(
                title: l10n.settingsApp,
                children: [
                  SettingsTile.navigation(
                    icon: AppIcons.settingsAppearance,
                    iconColor: SettingsHue.appearance,
                    title: l10n.settingsAppearance,
                    subtitle: l10n.settingsAppearanceSummary,
                    onTap: () => context.pushNamed(AppRoute.settingsAppearance),
                  ),
                  SettingsTile.navigation(
                    icon: AppIcons.backup,
                    iconColor: SettingsHue.backup,
                    title: l10n.backupTitle,
                    subtitle: !backup.folderRead
                        ? null
                        : switch ((
                            backup.folder,
                            // Another build's automatic backups are not
                            // this one's.
                            backup.backups.where((b) => b.mine).firstOrNull,
                          )) {
                            (BackupFolderLost(:final name), _) =>
                              l10n.backupFolderLost(name),
                            (_, final last?) => l10n.backupSettingsLast(
                              backupDate(context, last.createdAt),
                            ),
                            _ => l10n.backupSettingsNone,
                          },
                    onTap: () => context.pushNamed(AppRoute.backup),
                  ),
                  SettingsTile.navigation(
                    icon: AppIcons.settingsStorage,
                    iconColor: SettingsHue.storage,
                    title: l10n.settingsStorage,
                    subtitle: sizes == null
                        ? l10n.settingsStorageSummaryPending
                        : l10n.settingsStorageSummary(
                            megabytes(
                              l10n,
                              sizes.coverBytes + sizes.onlineInfoBytes,
                            ),
                          ),
                    onTap: () => context.pushNamed(AppRoute.settingsStorage),
                  ),
                  SettingsTile.navigation(
                    icon: AppIcons.settingsAbout,
                    iconColor: SettingsHue.about,
                    title: l10n.settingsAbout,
                    subtitle: version == null
                        ? l10n.settingsAboutSummaryPending
                        : l10n.settingsAboutSummary(version.version),
                    onTap: () => context.pushNamed(AppRoute.settingsAbout),
                  ),
                ],
              ),
              if (!kReleaseMode) const DebugSection(),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(height: context.bottomBarInset(tabs: false)),
            ],
          ),
        ],
      ),
    );
  }
}
