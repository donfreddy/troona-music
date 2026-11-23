import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/backup/domain/entities/backup_summary.dart';
import 'package:troona/l10n/app_localizations.dart';

/// How the backup screens name parts, counts and dates.
extension BackupLabels on AppLocalizations {
  String partName(BackupPart part) => switch (part) {
    BackupPart.playlists => navPlaylists,
    BackupPart.likes => likedSongs,
    BackupPart.history => backupPartHistory,
    BackupPart.lyrics => backupPartLyrics,
    BackupPart.settings => backupPartSettings,
    BackupPart.equalizer => equalizerTitle,
  };

  /// The parts chosen, in their order, or "Everything".
  String partsList(Set<BackupPart> parts) => parts.containsAll(BackupPart.all)
      ? backupPartsEverything
      : [
          for (final p in BackupPart.values)
            if (parts.contains(p)) partName(p),
        ].join(', ');

  /// What [part] of [summary] holds, beside its box in a restore.
  String partDetail(BackupPart part, BackupSummary summary) => switch (part) {
    BackupPart.playlists => backupSummaryPlaylists(summary.playlists),
    BackupPart.likes => backupSummaryLikes(summary.likes),
    BackupPart.history => backupSummaryPlays(summary.plays),
    BackupPart.lyrics => backupSummaryLyrics(summary.lyrics),
    BackupPart.settings => backupSettingsReplace,
    BackupPart.equalizer => backupSummaryProfiles(summary.profiles),
  };

  /// A backup's line in the list: its playlists, likes and plays.
  String? summaryLine(BackupSummary? summary) {
    if (summary == null) return null;
    final counts = [
      if (summary.parts.contains(BackupPart.playlists))
        backupSummaryPlaylists(summary.playlists),
      if (summary.parts.contains(BackupPart.likes))
        backupSummaryLikes(summary.likes),
      if (summary.parts.contains(BackupPart.history))
        backupSummaryPlays(summary.plays),
    ];
    return counts.isEmpty ? null : counts.join(', ');
  }
}

IconData partIcon(BackupPart part) => switch (part) {
  BackupPart.playlists => AppIcons.playlist,
  BackupPart.likes => AppIcons.like,
  BackupPart.history => AppIcons.history,
  BackupPart.lyrics => AppIcons.lyrics,
  BackupPart.settings => AppIcons.settings,
  BackupPart.equalizer => AppIcons.equalizer,
};

/// When a backup was made, in the phone's language: "Nov 23, 2026 3:24 AM".
String backupDate(BuildContext context, DateTime at) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMMMd(locale).add_jm().format(at.toLocal());
}
