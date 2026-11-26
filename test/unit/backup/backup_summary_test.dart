import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/backup/domain/entities/backup_summary.dart';
import 'package:troona/features/equalizer/domain/entities/equalizer_settings.dart';
import 'package:troona/features/equalizer/domain/entities/equalizer_snapshot.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';

const _track = BackupTrack(
  title: 'Song',
  artist: 'Artist',
  album: 'Album',
  durationMs: 1,
  fileName: 'a.mp3',
  size: 1,
);

Backup _backup({
  List<BackupPlaylist> playlists = const [],
  List<BackupPlay> plays = const [],
  List<BackupDay> days = const [],
  Set<BackupPart> parts = BackupPart.all,
  EqualizerSnapshot? equalizer,
  List<BackupLyrics> lyrics = const [],
  List<BackupLyricsOffset> lyricsOffsets = const [],
  List<BackupEdit> edits = const [],
}) => Backup(
  createdAt: DateTime.utc(2026),
  parts: parts,
  tracks: const {'a': _track, 'b': _track},
  playlists: playlists,
  plays: plays,
  days: days,
  trackDays: const [],
  firstPlays: const [],
  replayMonth: null,
  settings: parts.contains(BackupPart.settings) ? const AppSettings() : null,
  equalizer: equalizer,
  lyrics: lyrics,
  lyricsOffsets: lyricsOffsets,
  edits: edits,
);

void main() {
  test('counts each part and offers only the ones holding something', () {
    final summary = BackupSummary.of(
      _backup(
        playlists: const [
          BackupPlaylist(name: 'Liked', isLikes: true, tracks: ['a', 'b']),
          BackupPlaylist(name: 'Mix', isLikes: false, tracks: []),
        ],
        days: const [
          BackupDay(day: 20000, plays: 7, listenedMs: 1),
          BackupDay(day: 20001, plays: 5, listenedMs: 1),
        ],
        equalizer: const EqualizerSnapshot(
          settings: EqualizerSettings(),
          profiles: [],
        ),
        lyrics: const [BackupLyrics(track: 'a', text: '[00:01.00]La')],
        lyricsOffsets: const [
          BackupLyricsOffset(track: 'a', offsetMs: 300),
          BackupLyricsOffset(track: 'b', offsetMs: -200),
        ],
        edits: const [BackupEdit(track: 'b', title: 'Mine')],
      ),
    );

    // A song counted once, whether imported, corrected or both.
    expect(summary.lyrics, 2);
    expect(summary.playlists, 1);
    expect(summary.likes, 2);
    expect(summary.plays, 12);
    expect(summary.profiles, 0);
    expect(summary.edits, 1);
    expect(summary.parts, BackupPart.all);
  });

  test('a part saved empty is not offered', () {
    final summary = BackupSummary.of(
      _backup(
        playlists: const [
          BackupPlaylist(name: 'Liked', isLikes: true, tracks: []),
        ],
      ),
    );

    expect(summary.parts, {BackupPart.settings});
  });

  test('listed plays count when the totals are behind them', () {
    final summary = BackupSummary.of(
      _backup(
        plays: [BackupPlay(track: 'a', at: DateTime.utc(2026))],
      ),
    );

    expect(summary.plays, 1);
    expect(summary.parts, contains(BackupPart.history));
  });

  test('only keeps the chosen parts and the songs they name', () {
    final backup = _backup(
      playlists: const [
        BackupPlaylist(name: 'Liked', isLikes: true, tracks: ['a']),
        BackupPlaylist(name: 'Mix', isLikes: false, tracks: ['b']),
      ],
      plays: [BackupPlay(track: 'b', at: DateTime.utc(2026))],
    );

    final likes = backup.only({BackupPart.likes, BackupPart.settings});

    expect(likes.parts, {BackupPart.likes, BackupPart.settings});
    expect(likes.playlists.single.name, 'Liked');
    expect(likes.tracks.keys, ['a']);
    expect(likes.plays, isEmpty);
    expect(likes.settings, isNotNull);
    // A part the backup does not hold cannot be chosen into it.
    expect(likes.only({BackupPart.history}).parts, isEmpty);
  });

  test('lyrics go with their part, and their songs with them', () {
    final backup = _backup(
      lyrics: const [BackupLyrics(track: 'a', text: '[00:01.00]La')],
      lyricsOffsets: const [BackupLyricsOffset(track: 'b', offsetMs: 300)],
    );

    final lyrics = backup.only({BackupPart.lyrics});
    final rest = backup.only(BackupPart.all.difference({BackupPart.lyrics}));

    expect(lyrics.lyrics, backup.lyrics);
    expect(lyrics.lyricsOffsets, backup.lyricsOffsets);
    expect(lyrics.tracks.keys, unorderedEquals(['a', 'b']));
    expect(rest.lyrics, isEmpty);
    expect(rest.lyricsOffsets, isEmpty);
    expect(rest.tracks, isEmpty);
  });
}
