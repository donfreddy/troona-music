import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/backup/domain/use_cases/restore_backup_use_case.dart';
import 'package:troona/features/backup/presentation/cubit/backup_cubit.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/domain/repositories/maintenance_repository.dart';
import 'package:troona/features/settings/presentation/cubit/maintenance_cubit.dart';
import 'package:troona/features/whats_new/presentation/release_notes.dart';
import 'package:troona/features/whats_new/presentation/widgets/whats_new_sheet.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/features/settings/presentation/widgets/segmented_row.dart';
import 'package:troona/features/settings/presentation/widgets/settings_section.dart';
import 'package:troona/features/settings/presentation/widgets/settings_tile.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/app_dialog.dart';
import 'package:troona/shared/widgets/app_toast.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, size: 24),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.settingsTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) => switch (state) {
          SettingsLoaded(:final settings) => _SettingsList(settings: settings),
          SettingsError() => Center(
            child: Text(
              l10n.settingsLoadError,
              style: TextStyle(color: context.colors.labelSecondary),
            ),
          ),
          _ => const Center(child: CupertinoActivityIndicator(radius: 14)),
        },
      ),
    );
  }
}

class _SettingsList extends StatelessWidget {
  final AppSettings settings;

  const _SettingsList({required this.settings});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SettingsCubit>();
    final maintenance = context.watch<MaintenanceCubit>().state;
    final sizes = maintenance.sizes;
    final backupBusy = context.watch<BackupCubit>().state;

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        SettingsSection(
          title: l10n.settingsPlayback,
          children: [
            SettingsTile.switchTile(
              icon: LucideIcons.volume1,
              iconColor: const Color(0xFF8B5CF6),
              title: l10n.settingsDuck,
              value: settings.duckAudioOnNotification,
              onChanged: cubit.setDuckAudioOnNotification,
            ),
            SettingsTile.switchTile(
              icon: LucideIcons.phoneOff,
              iconColor: const Color(0xFFEC4899),
              title: l10n.settingsPauseOnCall,
              value: settings.stopOnCallEnabled,
              onChanged: cubit.setStopOnCall,
            ),
            SettingsTile.switchTile(
              icon: LucideIcons.phoneCall,
              iconColor: const Color(0xFF10B981),
              title: l10n.settingsResumeAfterCall,
              value: settings.resumeAfterCallEnabled,
              onChanged: cubit.setResumeAfterCall,
            ),
          ],
        ),
        SettingsSection(
          title: l10n.settingsLibrary,
          children: [
            BlocBuilder<LibraryBloc, LibraryState>(
              buildWhen: (p, c) =>
                  (p is LibraryScanning) != (c is LibraryScanning),
              builder: (context, state) {
                final scanning = state is LibraryScanning;
                return SettingsTile(
                  icon: LucideIcons.refreshCw,
                  iconColor: const Color(0xFFF59E0B),
                  title: l10n.settingsRescan,
                  subtitle: scanning
                      ? l10n.settingsRescanning
                      : l10n.settingsRescanSubtitle,
                  trailing: scanning
                      ? const CupertinoActivityIndicator()
                      : null,
                  onTap: scanning
                      ? null
                      : () => context.read<LibraryBloc>().add(
                          const LibraryRefreshRequested(),
                        ),
                );
              },
            ),
            SettingsTile(
              icon: LucideIcons.imageOff,
              iconColor: const Color(0xFFEF4444),
              title: l10n.settingsCoversClear,
              subtitle: l10n.settingsCoversClearSubtitle,
              trailing: _SizeLabel(sizes?.coverBytes),
              onTap: maintenance.busy ? null : () => _clearCovers(context),
            ),
          ],
        ),
        SettingsSection(
          title: l10n.settingsOnline,
          footer: l10n.settingsOnlineFooter,
          children: [
            SettingsTile.switchTile(
              icon: LucideIcons.bookOpen,
              iconColor: const Color(0xFFD51007),
              title: l10n.settingsOnlineBios,
              value: settings.fetchOnlineMetadata,
              onChanged: cubit.setFetchOnlineMetadata,
            ),
            SettingsTile.switchTile(
              icon: LucideIcons.image,
              iconColor: const Color(0xFF10B981),
              title: l10n.settingsOnlinePhotos,
              value: settings.fetchArtistArtwork,
              onChanged: cubit.setFetchArtistArtwork,
            ),
            SettingsTile(
              icon: LucideIcons.eraser,
              iconColor: const Color(0xFFF97316),
              title: l10n.settingsOnlineClear,
              trailing: _SizeLabel(sizes?.onlineInfoBytes),
              onTap: maintenance.busy ? null : () => _clearOnlineInfo(context),
            ),
          ],
        ),
        SettingsSection(
          title: l10n.settingsAppearance,
          footer: l10n.settingsGlassFooter,
          children: [
            SegmentedRow<GlassQuality>(
              icon: LucideIcons.sparkles,
              iconColor: const Color(0xFF06B6D4),
              label: l10n.settingsGlass,
              values: GlassQuality.values,
              labels: [
                l10n.settingsGlassAuto,
                l10n.settingsGlassFull,
                l10n.settingsGlassLight,
                l10n.settingsGlassOff,
              ],
              selected: settings.glassQuality,
              onChanged: cubit.setGlassQuality,
            ),
            SettingsTile.switchTile(
              icon: LucideIcons.vibrate,
              iconColor: const Color(0xFFF43F5E),
              title: l10n.settingsHaptics,
              value: settings.hapticFeedbackEnabled,
              onChanged: cubit.setHapticFeedback,
            ),
          ],
        ),
        SettingsSection(
          title: l10n.settingsBackup,
          footer: l10n.settingsBackupFooter,
          children: [
            SettingsTile(
              icon: LucideIcons.hardDriveUpload,
              iconColor: const Color(0xFF3B82F6),
              title: l10n.backupExport,
              subtitle: l10n.backupExportSubtitle,
              onTap: backupBusy ? null : () => _exportBackup(context),
            ),
            SettingsTile(
              icon: LucideIcons.archiveRestore,
              iconColor: const Color(0xFF22C55E),
              title: l10n.backupRestore,
              subtitle: l10n.backupRestoreSubtitle,
              trailing: backupBusy ? const CupertinoActivityIndicator() : null,
              onTap: backupBusy ? null : () => _restoreBackup(context),
            ),
          ],
        ),
        SettingsSection(
          title: l10n.settingsSupport,
          children: [
            SettingsTile.navigation(
              icon: LucideIcons.sparkles,
              iconColor: const Color(0xFF8B5CF6),
              title: l10n.whatsNewTitle,
              subtitle: maintenance.version == null
                  ? null
                  : l10n.whatsNewVersion(maintenance.version!.version),
              onTap: () => showWhatsNewSheet(
                context,
                releaseFor(l10n, maintenance.version?.version),
              ),
            ),
            SettingsTile.navigation(
              icon: LucideIcons.messageSquareWarning,
              iconColor: const Color(0xFF6366F1),
              title: l10n.settingsReport,
              subtitle: l10n.settingsReportSubtitle,
              onTap: () => _shareReport(context),
            ),
            SettingsTile.navigation(
              icon: LucideIcons.shieldCheck,
              iconColor: const Color(0xFF0EA5E9),
              title: l10n.settingsPrivacy,
              onTap: () => context.pushNamed(AppRoute.privacy),
            ),
            SettingsTile.navigation(
              icon: LucideIcons.scrollText,
              iconColor: const Color(0xFF64748B),
              title: l10n.settingsLicenses,
              onTap: () => showLicensePage(
                context: context,
                applicationName: l10n.appName,
                applicationVersion: maintenance.version?.version,
              ),
            ),
          ],
        ),
        SettingsSection(
          title: l10n.settingsReset,
          children: [
            SettingsTile(
              icon: LucideIcons.listX,
              iconColor: const Color(0xFF64748B),
              title: l10n.settingsForgetQueue,
              onTap: () => _forgetQueue(context),
            ),
            SettingsTile(
              icon: LucideIcons.rotateCcw,
              iconColor: const Color(0xFFDC2626),
              title: l10n.settingsResetSettings,
              onTap: () => _resetSettings(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _Footer(version: maintenance.version),
        SizedBox(
          height:
              AppSpacing.bottomBlockHeight +
              MediaQuery.paddingOf(context).bottom +
              AppSpacing.xl,
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
    // user leaves Settings while the files are being deleted.
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

  Future<void> _exportBackup(BuildContext context) async {
    final l10n = context.l10n;
    final overlay = Overlay.of(context, rootOverlay: true);
    // share_plus copies the file before the share sheet opens, so the
    // cubit deletes its own once this returns.
    final result = await context.read<BackupCubit>().export(
      (path) => SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'application/json')],
          subject: l10n.backupShareSubject,
        ),
      ),
    );
    if (result.isLeft()) AppToast.showOn(overlay, l10n.errorGeneric);
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.backupRestoreConfirmTitle,
      body: l10n.backupRestoreConfirmBody,
      confirmLabel: l10n.backupRestoreAction,
    );
    if (!confirmed || !context.mounted) return;
    // Captured up front: the restore finishes even if Settings closes.
    final backup = context.read<BackupCubit>();
    final settings = context.read<SettingsCubit>();
    final likes = context.read<LikesCubit>();

    final picked = await FilePicker.pickFiles();
    final path = picked?.files.singleOrNull?.path;
    if (path == null) return;
    final result = await backup.restore(path);
    // The picker's copy holds the listening history: not left behind.
    unawaited(FilePicker.clearTemporaryFiles());

    final report = result.fold((_) => null, (report) => report);
    if (report != null) {
      await settings.restore(report.settings);
      unawaited(likes.loadAllLikes());
    }
    if (!context.mounted) return;
    await result.fold(
      (failure) => showMessageDialog(
        context,
        title: l10n.backupRestore,
        body: switch (failure) {
          BackupTooNewFailure() => l10n.backupRestoreTooNew,
          BackupFormatFailure() => l10n.backupRestoreInvalid,
          _ => l10n.errorGeneric,
        },
      ),
      (report) => showMessageDialog(
        context,
        title: l10n.backupRestoreDoneTitle,
        body: _restoreSummary(l10n, report),
      ),
    );
  }

  static const _missingShown = 5;

  String _restoreSummary(AppLocalizations l10n, RestoreReport report) {
    final missing = report.missing;
    return [
      l10n.backupRestoreFound(report.found, report.total),
      if (missing.isNotEmpty)
        [
          l10n.backupRestoreMissing(missing.length),
          for (final t in missing.take(_missingShown))
            '${t.title}, ${t.artist}',
          if (missing.length > _missingShown)
            l10n.backupRestoreMore(missing.length - _missingShown),
        ].join('\n'),
      if (report.settings.onlineExtrasEnabled) l10n.backupRestoreOnline,
    ].join('\n\n');
  }

  Future<void> _shareReport(BuildContext context) async {
    final l10n = context.l10n;
    final library = context.read<LibraryBloc>().state;
    final trackCount = switch (library) {
      LibraryLoaded(:final allTracks) => allTracks.length,
      LibraryScanning(:final cached?) => cached.allTracks.length,
      _ => 0,
    };
    final report = await context.read<MaintenanceCubit>().problemReport(
      trackCount: trackCount,
    );
    await SharePlus.instance.share(
      ShareParams(text: report, subject: l10n.settingsReportSubject),
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
    await context.read<SettingsCubit>().resetToDefaults();
  }
}

class _SizeLabel extends StatelessWidget {
  final int? bytes;

  const _SizeLabel(this.bytes);

  @override
  Widget build(BuildContext context) {
    final b = bytes;
    final mb = b == null ? null : b / (1024 * 1024);
    return Text(
      mb == null ? '…' : context.l10n.sizeMegabytes(mb.toStringAsFixed(1)),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.colors.labelSecondary,
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final AppVersion? version;

  const _Footer({required this.version});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final v = version;
    return Column(
      children: [
        Icon(LucideIcons.music, size: 20, color: colors.labelTertiary),
        const SizedBox(height: 6),
        if (v != null)
          Text(
            context.l10n.settingsVersion(v.version, v.build),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.labelTertiary,
            ),
          ),
        const SizedBox(height: 2),
        Text(
          context.l10n.settingsTagline,
          style: TextStyle(fontSize: 11, color: colors.labelTertiary),
        ),
      ],
    );
  }
}
