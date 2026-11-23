import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/backup/domain/entities/backup_summary.dart';
import 'package:troona/features/backup/domain/use_cases/restore_backup_use_case.dart';
import 'package:troona/features/backup/presentation/cubit/backup_cubit.dart';
import 'package:troona/features/backup/presentation/utils/backup_labels.dart';
import 'package:troona/features/backup/presentation/widgets/backup_parts_sheet.dart';
import 'package:troona/features/equalizer/presentation/cubit/equalizer_cubit.dart';
import 'package:troona/features/library/domain/services/track_tags.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/app_dialog.dart';

/// Reads a backup with [open], asks which of its parts to restore (every
/// part it holds, all ticked), restores them and says how it went.
Future<void> restoreBackup(
  BuildContext context,
  Future<Either<Failure, Backup>> Function(BackupCubit cubit) open,
) async {
  final l10n = context.l10n;
  // Captured up front: the restore finishes even if the page closes.
  final cubit = context.read<BackupCubit>();
  final settings = context.read<SettingsCubit>();
  final likes = context.read<LikesCubit>();
  final equalizer = context.read<EqualizerCubit?>();

  final opened = await open(cubit);
  if (!context.mounted) return;
  final backup = opened.fold((_) => null, (b) => b);
  if (backup == null) {
    final failure = opened.fold((f) => f, (_) => null);
    await showMessageDialog(
      context,
      title: l10n.backupRestore,
      body: failureText(l10n, failure),
    );
    return;
  }

  final summary = BackupSummary.of(backup);
  final parts = [
    for (final p in BackupPart.values)
      if (summary.parts.contains(p)) p,
  ];
  if (parts.isEmpty) {
    await showMessageDialog(
      context,
      title: l10n.backupRestore,
      body: l10n.backupRestoreNothing,
    );
    return;
  }
  final chosen = await showBackupPartsSheet(
    context,
    title: l10n.backupRestoreTitle,
    message: l10n.backupRestoreFrom(backupDate(context, backup.createdAt)),
    parts: parts,
    initial: parts.toSet(),
    detail: (part) => l10n.partDetail(part, summary),
    confirmLabel: l10n.backupRestoreButton,
  );
  if (chosen == null) return;

  final result = await cubit.restore(backup, chosen);
  final report = result.fold((_) => null, (r) => r);
  if (report != null) {
    if (report.settings case final saved?) await settings.restore(saved);
    if (report.equalizer case final eq?) {
      equalizer?.restore(eq.settings, eq.profiles);
    }
    if (chosen.contains(BackupPart.likes)) await likes.loadAllLikes();
  }
  if (!context.mounted) return;
  await showMessageDialog(
    context,
    title: report == null ? l10n.backupRestore : l10n.backupRestoreDoneTitle,
    body: report == null
        ? failureText(l10n, result.fold((f) => f, (_) => null))
        : reportText(l10n, report),
  );
}

/// What went wrong reading or restoring a backup, for the user.
String failureText(AppLocalizations l10n, Failure? failure) =>
    switch (failure) {
      BackupTooNewFailure() => l10n.backupRestoreTooNew,
      BackupFormatFailure() => l10n.backupRestoreInvalid,
      BackupFolderLostFailure() => l10n.backupFolderLostError,
      _ => l10n.errorGeneric,
    };

const _missingShown = 5;

/// How a restore went: the songs found, the ones missing, and a word on
/// online extras when the backup had them on.
String reportText(AppLocalizations l10n, RestoreReport report) {
  final missing = report.missing;
  final lines = [
    // Settings alone name no song.
    if (report.total > 0) l10n.backupRestoreFound(report.found, report.total),
    if (missing.isNotEmpty)
      [
        l10n.backupRestoreMissing(missing.length),
        for (final t in missing.take(_missingShown))
          TrackTags.isUnknownArtist(t.artist)
              ? t.title
              : '${t.title}, ${t.artist}',
        if (missing.length > _missingShown)
          l10n.backupRestoreMore(missing.length - _missingShown),
      ].join('\n'),
    if (report.settings?.onlineExtrasEnabled ?? false) l10n.backupRestoreOnline,
  ];
  return lines.isEmpty ? l10n.backupRestoreDoneBody : lines.join('\n\n');
}
