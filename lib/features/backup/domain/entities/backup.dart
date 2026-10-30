import 'package:equatable/equatable.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';

/// A song as a backup describes it: enough to find it again on another
/// phone, where its device id is different.
final class BackupTrack extends Equatable {
  final String title;
  final String artist;
  final String album;
  final int durationMs;
  final String fileName;
  final int size;

  const BackupTrack({
    required this.title,
    required this.artist,
    required this.album,
    required this.durationMs,
    required this.fileName,
    required this.size,
  });

  @override
  List<Object?> get props => [title, artist, album, durationMs, fileName, size];
}

/// Songs are named by their key in [Backup.tracks].
final class BackupPlaylist extends Equatable {
  final String name;
  final bool isLikes;
  final List<String> tracks;

  const BackupPlaylist({
    required this.name,
    required this.isLikes,
    required this.tracks,
  });

  @override
  List<Object?> get props => [name, isLikes, tracks];
}

final class BackupPlay extends Equatable {
  final String track;
  final DateTime at;

  const BackupPlay({required this.track, required this.at});

  @override
  List<Object?> get props => [track, at];
}

/// Days are `ListeningDay` keys.
final class BackupDay extends Equatable {
  final int day;
  final int plays;
  final int listenedMs;

  const BackupDay({
    required this.day,
    required this.plays,
    required this.listenedMs,
  });

  @override
  List<Object?> get props => [day, plays, listenedMs];
}

final class BackupTrackDay extends Equatable {
  final int day;
  final String track;
  final int plays;

  const BackupTrackDay({
    required this.day,
    required this.track,
    required this.plays,
  });

  @override
  List<Object?> get props => [day, track, plays];
}

final class BackupFirstPlay extends Equatable {
  final String track;
  final int day;

  const BackupFirstPlay({required this.track, required this.day});

  @override
  List<Object?> get props => [track, day];
}

/// Everything a backup carries. Songs are described once in [tracks] and
/// named by their key everywhere else.
final class Backup extends Equatable {
  final DateTime createdAt;
  final Map<String, BackupTrack> tracks;
  final List<BackupPlaylist> playlists;
  final List<BackupPlay> plays;
  final List<BackupDay> days;
  final List<BackupTrackDay> trackDays;
  final List<BackupFirstPlay> firstPlays;

  /// The last month whose Replay playlist was made, as `MonthlyReplayLog`
  /// keeps it.
  final int? replayMonth;
  final AppSettings settings;

  const Backup({
    required this.createdAt,
    required this.tracks,
    required this.playlists,
    required this.plays,
    required this.days,
    required this.trackDays,
    required this.firstPlays,
    required this.replayMonth,
    required this.settings,
  });

  @override
  List<Object?> get props => [
    createdAt,
    tracks,
    playlists,
    plays,
    days,
    trackDays,
    firstPlays,
    replayMonth,
    settings,
  ];
}
