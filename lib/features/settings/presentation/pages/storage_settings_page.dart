import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/equalizer/presentation/cubit/equalizer_cubit.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/settings/presentation/cubit/maintenance_cubit.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/features/settings/presentation/widgets/settings_hue.dart';
import 'package:troona/features/settings/presentation/widgets/settings_section.dart';
import 'package:troona/features/settings/presentation/widgets/settings_subpage.dart';
import 'package:troona/features/settings/presentation/widgets/settings_tile.dart';
import 'package:troona/features/updates/presentation/cubit/update_cubit.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/app_dialog.dart';
import 'package:troona/shared/widgets/app_toast.dart';

/// [bytes] in megabytes, one decimal, written as the language writes it
/// ("30,0 Mo" in French).
String megabytes(AppLocalizations l10n, int bytes) => l10n.sizeMegabytes(
  NumberFormat('0.0', l10n.localeName).format(bytes / (1024 * 1024)),
);

/// The caches, measured and cleared, then starting over: the queue, the
/// settings.
class StorageSettingsPage extends StatefulWidget {
  const StorageSettingsPage({super.key});

  @override
  State<StorageSettingsPage> createState() => _StorageSettingsPageState();
}

class _StorageSettingsPageState extends State<StorageSettingsPage> {
  @override
  void initState() {
    super.initState();
    // Measured again on each visit: covers are extracted as songs come.
    unawaited(context.read<MaintenanceCubit>().load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maintenance = context.watch<MaintenanceCubit>().state;
    final sizes = maintenance.sizes;
    return SettingsSubpage(
      title: l10n.settingsStorage,
      intro: l10n.settingsStorageIntro,
      children: [
        SettingsSection(
          title: l10n.settingsCache,
          children: [
            SettingsTile(
              icon: AppIcons.clearCovers,
              iconColor: SettingsHue.storage,
              title: l10n.settingsCoversClear,
              subtitle: l10n.settingsCoversClearSubtitle,
              trailing: _SizeLabel(sizes?.coverBytes),
              onTap: maintenance.busy ? null : () => _clearCovers(context),
            ),
            SettingsTile(
              icon: AppIcons.clearOnlineInfo,
              iconColor: SettingsHue.storage,
              title: l10n.settingsOnlineClear,
              subtitle: l10n.settingsOnlineClearSubtitle,
              trailing: _SizeLabel(sizes?.onlineInfoBytes),
              onTap: maintenance.busy ? null : () => _clearOnlineInfo(context),
            ),
          ],
        ),
        SettingsSection(
          title: l10n.settingsReset,
          children: [
            SettingsTile(
              icon: AppIcons.removeFromList,
              iconColor: SettingsHue.storage,
              title: l10n.settingsForgetQueue,
              subtitle: l10n.settingsForgetQueueSubtitle,
              destructive: true,
              onTap: () => _forgetQueue(context),
            ),
            SettingsTile(
              icon: AppIcons.reset,
              iconColor: SettingsHue.storage,
              title: l10n.settingsResetSettings,
              subtitle: l10n.settingsResetSettingsSubtitle,
              destructive: true,
              onTap: () => _resetSettings(context),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _clearCovers(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.settingsCoversConfirmTitle,
      body: l10n.settingsCoversConfirmBody,
      confirmLabel: l10n.actionClear,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    // Captured up front: the rescan and the toast must happen even if the
    // user leaves the page while the files are being deleted.
    final library = context.read<LibraryBloc>();
    final overlay = Overlay.of(context, rootOverlay: true);
    final ok = await context.read<MaintenanceCubit>().clearCovers();
    library.add(const LibraryRefreshRequested());
    AppToast.showOn(
      overlay,
      ok ? l10n.settingsCoversCleared : l10n.errorGeneric,
    );
  }

  Future<void> _clearOnlineInfo(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.settingsOnlineConfirmTitle,
      body: l10n.settingsOnlineConfirmBody,
      confirmLabel: l10n.actionClear,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    final ok = await context.read<MaintenanceCubit>().clearOnlineInfo();
    AppToast.showOn(
      overlay,
      ok ? l10n.settingsOnlineCleared : l10n.errorGeneric,
    );
  }

  Future<void> _forgetQueue(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.settingsForgetQueueConfirmTitle,
      body: l10n.settingsForgetQueueConfirmBody,
      confirmLabel: l10n.actionClear,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    // Stops the engine and clears the saved session in one place.
    context.read<PlayerBloc>().add(const PlayerDismissed());
    AppToast.show(context, l10n.settingsForgetQueueDone);
  }

  Future<void> _resetSettings(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.settingsResetConfirmTitle,
      body: l10n.settingsResetConfirmBody,
      confirmLabel: l10n.actionReset,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final updates = context.read<UpdateCubit>();
    // Off and flat; the saved profiles stay, as playlists do.
    context.read<EqualizerCubit?>()?.resetAll();
    await context.read<SettingsCubit>().resetToDefaults();
    updates.clear();
  }
}

class _SizeLabel extends StatelessWidget {
  final int? bytes;

  const _SizeLabel(this.bytes);

  @override
  Widget build(BuildContext context) {
    final b = bytes;
    return Text(
      b == null ? '…' : megabytes(context.l10n, b),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.colors.labelSecondary,
      ),
    );
  }
}
