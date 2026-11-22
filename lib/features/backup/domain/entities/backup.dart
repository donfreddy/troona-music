import 'package:equatable/equatable.dart';
import 'package:troona/features/library/domain/entities/smart_rules.dart';
import 'package:troona/features/equalizer/domain/entities/equalizer_snapshot.dart';
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

/// Songs are named by their key in [Backup.tracks]. A smart playlist has
/// [rules] and no songs.
final class BackupPlaylist extends Equatable {
  final String name;
  final bool isLikes;
  final List<String> tracks;
  final SmartRules? rules;

  const BackupPlaylist({
    required this.name,
    required this.isLikes,
    required this.tracks,
    this.rules,
  });

  @override
  List<Object?> get props => [name, isLikes, tracks, rules];
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

/// Plays started in one hour: [hour] is `day * 24 + hour`, the day a
/// `ListeningDay` key, the hour local.
final class BackupHour extends Equatable {
  final int hour;
  final int plays;

  const BackupHour({required this.hour, required this.plays});

  @override
  List<Object?> get props => [hour, plays];
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

/// What a backup can hold, picked by the user when saving and again when
/// restoring.
enum BackupPart {
  /// Playlists of songs and smart playlists.
  playlists,
  likes,

  /// Plays, daily totals, plays per song and per hour, first plays and the
  /// last Replay month: one block, since its parts count the same plays.
  history,
  settings,
  equalizer;

  static const all = {playlists, likes, history, settings, equalizer};
}

/// Everything a backup carries. Songs are described once in [tracks] and
/// named by their key everywhere else.
///
/// [parts] says what it was saved with: a part left out has no records
/// (and [settings] is null without [BackupPart.settings]).
final class Backup extends Equatable {
  final DateTime createdAt;
  final Set<BackupPart> parts;
  final Map<String, BackupTrack> tracks;
  final List<BackupPlaylist> playlists;
  final List<BackupPlay> plays;
  final List<BackupDay> days;
  final List<BackupTrackDay> trackDays;
  final List<BackupFirstPlay> firstPlays;

  /// Empty in backups made before the hours were counted.
  final List<BackupHour> hours;

  /// The last month whose Replay playlist was made, as `MonthlyReplayLog`
  /// keeps it.
  final int? replayMonth;
  final AppSettings? settings;

  /// Absent from backups made before the equalizer, or when it could not be
  /// read: the rest restores without it.
  final EqualizerSnapshot? equalizer;

  const Backup({
    required this.createdAt,
    this.parts = BackupPart.all,
    required this.tracks,
    required this.playlists,
    required this.plays,
    required this.days,
    required this.trackDays,
    required this.firstPlays,
    this.hours = const [],
    required this.replayMonth,
    required this.settings,
    this.equalizer,
  });

  /// Whether it holds every part: such a file is written in the first
  /// format version, which older apps read.
  bool get complete => parts.containsAll(BackupPart.all);

  Backup withEqualizer(EqualizerSnapshot? equalizer) => Backup(
    createdAt: createdAt,
    parts: parts,
    tracks: tracks,
    playlists: playlists,
    plays: plays,
    days: days,
    trackDays: trackDays,
    firstPlays: firstPlays,
    hours: hours,
    replayMonth: replayMonth,
    settings: settings,
    equalizer: equalizer,
  );

  /// This backup with the records of [chosen] parts only, and the songs
  /// they name: what a restore of those parts writes.
  Backup only(Set<BackupPart> chosen) {
    final keep = parts.intersection(chosen);
    final history = keep.contains(BackupPart.history);
    final playlists = [
      for (final p in this.playlists)
        if (keep.contains(p.isLikes ? BackupPart.likes : BackupPart.playlists))
          p,
    ];
    final plays = history ? this.plays : const <BackupPlay>[];
    final trackDays = history ? this.trackDays : const <BackupTrackDay>[];
    final firstPlays = history ? this.firstPlays : const <BackupFirstPlay>[];
    final named = {
      for (final p in playlists) ...p.tracks,
      for (final p in plays) p.track,
      for (final d in trackDays) d.track,
      for (final f in firstPlays) f.track,
    };
    return Backup(
      createdAt: createdAt,
      parts: keep,
      tracks: {
        for (final MapEntry(:key, :value) in tracks.entries)
          if (named.contains(key)) key: value,
      },
      playlists: playlists,
      plays: plays,
      days: history ? days : const [],
      trackDays: trackDays,
      firstPlays: firstPlays,
      hours: history ? hours : const [],
      replayMonth: history ? replayMonth : null,
      settings: keep.contains(BackupPart.settings) ? settings : null,
      equalizer: keep.contains(BackupPart.equalizer) ? equalizer : null,
    );
  }

  @override
  List<Object?> get props => [
    createdAt,
    parts,
    tracks,
    playlists,
    plays,
    days,
    trackDays,
    firstPlays,
    hours,
    replayMonth,
    settings,
    equalizer,
  ];
}
