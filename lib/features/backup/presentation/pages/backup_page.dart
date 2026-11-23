import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/backup/domain/entities/backup_preferences.dart';
import 'package:troona/features/backup/domain/entities/stored_backup.dart';
import 'package:troona/features/backup/presentation/cubit/backup_cubit.dart';
import 'package:troona/features/backup/presentation/utils/backup_labels.dart';
import 'package:troona/features/backup/presentation/utils/restore_flow.dart';
import 'package:troona/features/backup/presentation/widgets/backup_parts_sheet.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/settings/presentation/widgets/settings_section.dart';
import 'package:troona/features/settings/presentation/widgets/settings_tile.dart';
import 'package:troona/shared/widgets/action_sheet.dart';
import 'package:troona/shared/widgets/app_back_button.dart';
import 'package:troona/shared/widgets/app_badge.dart';
import 'package:troona/shared/widgets/app_dialog.dart';
import 'package:troona/shared/widgets/app_icon_button.dart';
import 'package:troona/shared/widgets/app_toast.dart';
import 'package:troona/shared/widgets/glass_sliver_header.dart';

/// Backups by hand and automatic, the folder they go to, and restores
/// (Settings > Backup & restore).
class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  static const _autoColor = Color(0xFF6366F1);
  static const _folderColor = Color(0xFFF59E0B);
  static const _partsColor = Color(0xFF8B5CF6);
  static const _backupColor = Color(0xFF3B82F6);
  static const _restoreColor = Color(0xFF22C55E);

  /// The row whose task runs, for its spinner: 'now', 'file' or a backup's
  /// id. The cubit says whether a task runs, not which row started it.
  String? _working;

  Future<void> _run(String row, Future<void> Function() task) async {
    setState(() => _working = row);
    try {
      await task();
    } finally {
      if (mounted) setState(() => _working = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<BackupCubit, BackupState>(
        builder: (context, state) {
          final folder = state.folder;
          final ready = folder is BackupFolderReady ? folder.folder : null;
          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              GlassSliverHeader.largeTitle(
                leading: const AppBackButton(),
                title: l10n.backupTitle,
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  context.bottomBarInset(tabs: false),
                ),
                sliver: SliverList.list(
                  children: [
                    if (folder is! BackupFolderUnsupported)
                      _autoSection(context, state),
                    _manualSection(context, state, ready),
                    _restoreSection(context, state, ready),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _autoSection(BuildContext context, BackupState state) {
    final l10n = context.l10n;
    final preferences = state.preferences;
    final lastAuto = state.lastAuto;
    return SettingsSection(
      title: l10n.backupAutoSection,
      footer: l10n.backupFolderFooter,
      children: [
        SettingsTile.switchTile(
          icon: AppIcons.backupAuto,
          iconColor: _autoColor,
          title: l10n.backupAuto,
          subtitle: !preferences.auto
              ? l10n.backupAutoOff
              : lastAuto == null
              ? l10n.backupAutoNone
              : l10n.backupAutoLast(backupDate(context, lastAuto.createdAt)),
          value: preferences.auto,
          enabled: !state.busy,
          onChanged: (on) => _setAuto(context, on),
        ),
        SettingsTile.navigation(
          icon: AppIcons.recent,
          iconColor: _autoColor,
          title: l10n.backupFrequency,
          value: _frequencyLabel(context, preferences.frequency),
          enabled: preferences.auto,
          onTap: () => _pickFrequency(context, preferences.frequency),
        ),
        SettingsTile.navigation(
          icon: AppIcons.backupFolder,
          iconColor: _folderColor,
          title: l10n.backupFolder,
          subtitle: switch (state.folder) {
            BackupFolderReady(:final folder) => folder.name,
            BackupFolderLost(:final name) => l10n.backupFolderLost(name),
            _ => l10n.backupFolderChoose,
          },
          enabled: !state.busy,
          onTap: () => _pickFolder(context),
        ),
      ],
    );
  }

  Widget _manualSection(
    BuildContext context,
    BackupState state,
    BackupFolder? ready,
  ) {
    final l10n = context.l10n;
    final saving = state.busy && _working == 'now';
    return SettingsSection(
      title: l10n.backupManualSection,
      footer: l10n.settingsBackupFooter,
      children: [
        SettingsTile.navigation(
          icon: AppIcons.backupParts,
          iconColor: _partsColor,
          title: l10n.backupParts,
          subtitle: l10n.partsList(state.preferences.parts),
          onTap: () => _pickParts(context, state.preferences.parts),
        ),
        SettingsTile(
          icon: AppIcons.backup,
          iconColor: _backupColor,
          title: l10n.backupNow,
          subtitle: ready == null
              ? l10n.backupExportSubtitle
              : l10n.backupNowInto(ready.name),
          trailing: saving ? const CupertinoActivityIndicator() : null,
          onTap: state.busy
              ? null
              : () => _run('now', () => _backUpNow(context, ready)),
        ),
      ],
    );
  }

  Widget _restoreSection(
    BuildContext context,
    BackupState state,
    BackupFolder? ready,
  ) {
    final l10n = context.l10n;
    return SettingsSection(
      title: l10n.backupRestoreSection,
      children: [
        if (ready != null && state.backups.isEmpty)
          SettingsTile(
            icon: AppIcons.info,
            iconColor: _restoreColor,
            title: l10n.backupNone,
          ),
        for (final backup in state.backups)
          SettingsTile(
            key: ValueKey(backup.id),
            icon: backup.auto ? AppIcons.backupAuto : AppIcons.restore,
            iconColor: _restoreColor,
            title: backupDate(context, backup.createdAt),
            subtitle: l10n.summaryLine(state.summaries[backup.id]),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (backup.auto) AppBadge(l10n.backupAutoBadge),
                if (state.busy && _working == backup.id)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: CupertinoActivityIndicator(),
                  )
                else
                  AppIconButton(
                    icon: AppIcons.more,
                    tooltip: l10n.backupOptions,
                    onPressed: state.busy
                        ? null
                        : () => _backupActions(context, backup, ready),
                  ),
              ],
            ),
            onTap: state.busy
                ? null
                : () => _run(backup.id, () => _restore(context, backup)),
          ),
        SettingsTile(
          icon: AppIcons.backupFromFile,
          iconColor: _restoreColor,
          title: l10n.backupFromFile,
          subtitle: l10n.backupFromFileSubtitle,
          trailing: state.busy && _working == 'file'
              ? const CupertinoActivityIndicator()
              : null,
          onTap: state.busy
              ? null
              : () => _run('file', () => _fromFile(context)),
        ),
      ],
    );
  }

  String _frequencyLabel(BuildContext context, BackupFrequency frequency) =>
      switch (frequency) {
        BackupFrequency.daily => context.l10n.backupDaily,
        BackupFrequency.weekly => context.l10n.backupWeekly,
      };

  Future<void> _setAuto(BuildContext context, bool on) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final l10n = context.l10n;
    final result = await context.read<BackupCubit>().setAuto(on);
    if (result.isLeft()) AppToast.showOn(overlay, l10n.errorGeneric);
  }

  Future<void> _pickFrequency(BuildContext context, BackupFrequency current) {
    final cubit = context.read<BackupCubit>();
    return showActionSheet(
      context,
      title: context.l10n.backupFrequency,
      actions: [
        for (final frequency in BackupFrequency.values)
          SheetAction(
            label: _frequencyLabel(context, frequency),
            selected: frequency == current,
            onPressed: () => cubit.setFrequency(frequency),
          ),
      ],
    );
  }

  Future<void> _pickFolder(BuildContext context) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final l10n = context.l10n;
    final result = await context.read<BackupCubit>().pickFolder();
    if (result.isLeft()) AppToast.showOn(overlay, l10n.errorGeneric);
  }

  Future<void> _pickParts(BuildContext context, Set<BackupPart> current) async {
    final l10n = context.l10n;
    final cubit = context.read<BackupCubit>();
    final chosen = await showBackupPartsSheet(
      context,
      title: l10n.backupParts,
      parts: BackupPart.values,
      initial: current,
      confirmLabel: l10n.actionDone,
    );
    if (chosen != null) await cubit.setParts(chosen);
  }

  Future<void> _backUpNow(BuildContext context, BackupFolder? ready) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final l10n = context.l10n;
    final cubit = context.read<BackupCubit>();
    if (ready == null) {
      // share_plus copies the file before the share sheet opens, so the
      // cubit deletes its own once this returns.
      final shared = await cubit.export(_share(l10n.backupShareSubject));
      if (shared.isLeft()) AppToast.showOn(overlay, l10n.errorGeneric);
      return;
    }
    final saved = await cubit.backUpNow();
    AppToast.showOn(
      overlay,
      saved.fold(
        (f) => f is BackupFolderLostFailure
            ? l10n.backupFolderLostError
            : l10n.errorGeneric,
        (_) => l10n.backupSaved,
      ),
    );
  }

  Future<void> _restore(BuildContext context, StoredBackup backup) =>
      restoreBackup(context, (cubit) => cubit.open(backup));

  Future<void> _fromFile(BuildContext context) async {
    final picked = await FilePicker.pickFiles();
    final path = picked?.files.singleOrNull?.path;
    if (path == null || !context.mounted) return;
    try {
      await restoreBackup(context, (cubit) => cubit.openFile(path));
    } finally {
      // The picker's copy holds the listening history: not left behind.
      unawaited(FilePicker.clearTemporaryFiles());
    }
  }

  Future<void> _backupActions(
    BuildContext context,
    StoredBackup backup,
    BackupFolder? folder,
  ) {
    final l10n = context.l10n;
    final cubit = context.read<BackupCubit>();
    final overlay = Overlay.of(context, rootOverlay: true);
    return showActionSheet(
      context,
      title: backupDate(context, backup.createdAt),
      message: l10n.summaryLine(cubit.state.summaries[backup.id]),
      actions: [
        SheetAction(
          label: l10n.backupRestoreButton,
          icon: AppIcons.restore,
          onPressed: () => _run(backup.id, () => _restore(context, backup)),
        ),
        SheetAction(
          label: l10n.backupShare,
          icon: AppIcons.share,
          onPressed: () => _run(backup.id, () async {
            final shared = await cubit.share(
              backup,
              _share(l10n.backupShareSubject),
            );
            if (shared.isLeft()) AppToast.showOn(overlay, l10n.errorGeneric);
          }),
        ),
        SheetAction(
          label: l10n.actionDelete,
          icon: AppIcons.delete,
          destructive: true,
          onPressed: () => _delete(context, backup, folder),
        ),
      ],
    );
  }

  Future<void> _delete(
    BuildContext context,
    StoredBackup backup,
    BackupFolder? folder,
  ) async {
    final l10n = context.l10n;
    final overlay = Overlay.of(context, rootOverlay: true);
    final cubit = context.read<BackupCubit>();
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.backupDeleteTitle,
      body: l10n.backupDeleteBody(folder?.name ?? ''),
      confirmLabel: l10n.actionDelete,
      destructive: true,
    );
    if (!confirmed) return;
    final deleted = await cubit.delete(backup);
    if (deleted.isLeft()) AppToast.showOn(overlay, l10n.errorGeneric);
  }

  static Future<void> Function(String path) _share(String subject) =>
      (path) => SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'application/json')],
          subject: subject,
        ),
      );
}
