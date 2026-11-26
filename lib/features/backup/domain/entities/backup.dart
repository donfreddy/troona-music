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

  /// Lyrics imported by hand, and the timing set on lyrics found online.
  lyrics,

  /// Songs' info corrected in the app (title, artist, album, year); a
  /// picked cover is a file of this phone and stays here.
  edits,
  settings,
  equalizer;

  static const all = {
    playlists,
    likes,
    history,
    lyrics,
    edits,
    settings,
    equalizer,
  };
}

/// Lyrics the user imported for a song, with their timing correction
/// (positive shows the lines earlier). Lyrics found online are not carried:
/// they are found again; their correction is ([BackupLyricsOffset]).
final class BackupLyrics extends Equatable {
  final String track;
  final String text;
  final int offsetMs;

  const BackupLyrics({
    required this.track,
    required this.text,
    this.offsetMs = 0,
  });

  @override
  List<Object?> get props => [track, text, offsetMs];
}

/// The timing correction set by hand on lyrics found online: the lyrics
/// are found again on another phone, the correction would not be.
final class BackupLyricsOffset extends Equatable {
  final String track;
  final int offsetMs;

  const BackupLyricsOffset({required this.track, required this.offsetMs});

  @override
  List<Object?> get props => [track, offsetMs];
}

/// A song's info corrected in the app (see `TrackEdit`), its cover left
/// out. A null field is not corrected.
final class BackupEdit extends Equatable {
  final String track;
  final String? title;
  final String? artist;
  final String? album;
  final int? year;

  const BackupEdit({
    required this.track,
    this.title,
    this.artist,
    this.album,
    this.year,
  });

  bool get isEmpty =>
      title == null && artist == null && album == null && year == null;

  @override
  List<Object?> get props => [track, title, artist, album, year];
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

  /// Whether [settings] hold the accent and the black background: a backup
  /// made before them does not, nor one naming an accent this app lacks,
  /// and a restore then keeps this phone's.
  final bool appearanceSaved;

  /// Absent from backups made before the equalizer, or when it could not be
  /// read: the rest restores without it.
  final EqualizerSnapshot? equalizer;

  /// Empty in backups made before lyrics.
  final List<BackupLyrics> lyrics;

  /// Empty in backups made before they were carried.
  final List<BackupLyricsOffset> lyricsOffsets;

  /// Empty in backups made before corrections.
  final List<BackupEdit> edits;

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
    this.appearanceSaved = true,
    this.equalizer,
    this.lyrics = const [],
    this.lyricsOffsets = const [],
    this.edits = const [],
  });

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
    appearanceSaved: appearanceSaved,
    equalizer: equalizer,
    lyrics: lyrics,
    lyricsOffsets: lyricsOffsets,
    edits: edits,
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
    final withLyrics = keep.contains(BackupPart.lyrics);
    final lyrics = withLyrics ? this.lyrics : const <BackupLyrics>[];
    final lyricsOffsets = withLyrics
        ? this.lyricsOffsets
        : const <BackupLyricsOffset>[];
    final edits = keep.contains(BackupPart.edits)
        ? this.edits
        : const <BackupEdit>[];
    final named = {
      for (final p in playlists) ...p.tracks,
      for (final p in plays) p.track,
      for (final d in trackDays) d.track,
      for (final f in firstPlays) f.track,
      for (final l in lyrics) l.track,
      for (final o in lyricsOffsets) o.track,
      for (final e in edits) e.track,
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
      appearanceSaved: appearanceSaved,
      equalizer: keep.contains(BackupPart.equalizer) ? equalizer : null,
      lyrics: lyrics,
      lyricsOffsets: lyricsOffsets,
      edits: edits,
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
    appearanceSaved,
    equalizer,
    lyrics,
    lyricsOffsets,
    edits,
  ];
}
