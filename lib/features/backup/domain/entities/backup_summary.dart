import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';

/// What a backup holds, counted: shown in the list of backups and beside
/// each part a restore offers.
final class BackupSummary extends Equatable {
  /// The parts with something to restore: a part saved empty (no liked
  /// song, no play yet) is not offered.
  final Set<BackupPart> parts;

  /// Playlists of songs and smart playlists, likes left out.
  final int playlists;
  final int likes;

  /// Every play the history counted, not only the recent ones it lists.
  final int plays;

  /// Songs with imported lyrics or a timing set on lyrics found online.
  final int lyrics;

  /// Saved equalizer profiles.
  final int profiles;

  const BackupSummary({
    required this.parts,
    this.playlists = 0,
    this.likes = 0,
    this.plays = 0,
    this.lyrics = 0,
    this.profiles = 0,
  });

  factory BackupSummary.of(Backup backup) {
    final playlists = backup.playlists.where((p) => !p.isLikes).length;
    final likes = backup.playlists
        .where((p) => p.isLikes)
        .fold(0, (sum, p) => sum + p.tracks.length);
    // The daily totals count every play; a backup whose totals are behind
    // its listed plays still restores those.
    final plays = max(
      backup.days.fold(0, (sum, d) => sum + d.plays),
      backup.plays.length,
    );
    final history =
        plays > 0 ||
        backup.trackDays.isNotEmpty ||
        backup.firstPlays.isNotEmpty ||
        backup.hours.isNotEmpty;
    final lyrics = {
      for (final l in backup.lyrics) l.track,
      for (final o in backup.lyricsOffsets) o.track,
    }.length;
    return BackupSummary(
      parts: {
        if (playlists > 0) BackupPart.playlists,
        if (likes > 0) BackupPart.likes,
        if (history) BackupPart.history,
        if (lyrics > 0) BackupPart.lyrics,
        if (backup.settings != null) BackupPart.settings,
        if (backup.equalizer != null) BackupPart.equalizer,
      },
      playlists: playlists,
      likes: likes,
      plays: plays,
      lyrics: lyrics,
      profiles: backup.equalizer?.profiles.length ?? 0,
    );
  }

  @override
  List<Object?> get props => [parts, playlists, likes, plays, lyrics, profiles];
}
