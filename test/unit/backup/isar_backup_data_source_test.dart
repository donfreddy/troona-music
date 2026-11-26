import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/library/data/models/smart_rules_json.dart';
import 'package:troona/features/library/domain/entities/smart_rules.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/backup/data/backup_codec.dart';
import 'package:troona/features/backup/data/backup_repository_impl.dart';
import 'package:troona/features/history/data/sources/shared_prefs_monthly_replay_log.dart';
import 'package:troona/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:troona/features/backup/data/isar_backup_data_source.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/history/data/models/listening_models.dart';
import 'package:troona/features/history/data/models/play_event_model.dart';
import 'package:troona/features/history/data/sources/isar_play_history_data_source.dart';
import 'package:troona/features/lyrics/data/models/track_lyrics_model.dart';
import 'package:troona/features/lyrics/data/sources/isar_lyrics_data_source.dart';
import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/library/data/models/playlist_model.dart';
import 'package:troona/features/library/data/models/track_edit_model.dart';
import 'package:troona/features/library/data/models/track_model.dart';
import 'package:troona/features/library/data/sources/isar_track_edit_data_source.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/track_edit.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';

import '../../helpers/isar_host.dart';

TrackModel _track(String deviceId) => TrackModel()
  ..deviceId = deviceId
  ..path = '/music/$deviceId.mp3'
  ..uri = 'content://$deviceId'
  ..title = 'Title $deviceId'
  ..artist = 'Artist'
  ..artistId = 1
  ..album = 'Album'
  ..albumId = 1
  ..genre = ''
  ..genreId = 0
  ..durationMs = 200000
  ..fileName = '$deviceId.mp3'
  ..trackNumber = 1
  ..size = 42
  ..year = 2026
  ..indexedAt = DateTime(2026);

BackupTrack _saved(String key) => BackupTrack(
  title: 'Title $key',
  artist: 'Artist',
  album: 'Album',
  durationMs: 200000,
  fileName: '$key.mp3',
  size: 42,
);

void main() {
  late Directory dir;
  late Isar isar;
  late IsarBackupDataSource source;
  final t0 = DateTime(2026, 10, 24, 9);

  final library = hostIsarLibrary();
  final skip = library == null
      ? 'No Isar core for ${Platform.operatingSystem}'
      : null;

  setUpAll(() async {
    if (library != null) await Isar.initialize(library);
  });

  setUp(() async {
    if (skip != null) return;
    dir = await Directory.systemTemp.createTemp('backup_test');
    isar = Isar.open(
      schemas: [
        ...IsarLibraryDataSource.schemas,
        ...IsarPlayHistoryDataSource.schemas,
        ...IsarLyricsDataSource.schemas,
        ...IsarTrackEditDataSource.schemas,
      ],
      directory: dir.path,
      inspector: false,
    );
    source = IsarBackupDataSource(isar, maxPlays: 3);
  });

  tearDown(() async {
    if (skip != null) return;
    isar.close(deleteFromDisk: true);
    await dir.delete(recursive: true);
  });

  void store({
    List<TrackModel> tracks = const [],
    List<PlaylistModel> playlists = const [],
    List<PlayEventModel> plays = const [],
  }) => isar.write((isar) {
    for (final t in tracks) {
      isar.trackModels.put(t..id = isar.trackModels.autoIncrement());
    }
    for (final p in playlists) {
      isar.playlistModels.put(p..id = isar.playlistModels.autoIncrement());
    }
    for (final p in plays) {
      isar.playEventModels.put(p..id = isar.playEventModels.autoIncrement());
    }
  });

  PlaylistModel playlist(String id, String name, List<String> trackIds) =>
      PlaylistModel()
        ..playlistId = id
        ..name = name
        ..trackIds = trackIds;

  PlayEventModel play(String trackId, DateTime at) => PlayEventModel()
    ..trackId = trackId
    ..playedAt = at;

  Backup backup({
    List<BackupPlaylist> playlists = const [],
    List<BackupPlay> plays = const [],
    List<BackupDay> days = const [],
    List<BackupTrackDay> trackDays = const [],
    List<BackupFirstPlay> firstPlays = const [],
    List<BackupHour> hours = const [],
  }) => Backup(
    createdAt: t0,
    tracks: {
      for (final k in ['a', 'b', 'c']) k: _saved(k),
    },
    playlists: playlists,
    plays: plays,
    days: days,
    trackDays: trackDays,
    firstPlays: firstPlays,
    hours: hours,
    replayMonth: null,
    settings: const AppSettings(),
  );

  List<String> trackIdsOf(String name) => isar.playlistModels
      .where()
      .findAll()
      .firstWhere((p) => p.name == name)
      .trackIds;

  group('reading', () {
    test('describes only the songs something names', () {
      store(
        tracks: [_track('1'), _track('2'), _track('3')],
        playlists: [
          playlist(Playlist.likesId, 'Liked', ['1']),
        ],
        plays: [play('2', t0)],
      );

      final read = source.read(
        createdAt: t0,
        settings: const AppSettings(),
        replayMonth: 5,
      );

      expect(read.tracks.keys, unorderedEquals(['1', '2']));
      expect(read.playlists.single.isLikes, isTrue);
      expect(read.plays.single.track, '2');
      expect(read.replayMonth, 5);
    });

    test('leaves out songs gone from the library', () {
      store(
        tracks: [_track('1')],
        playlists: [
          playlist('p', 'Mix', ['1', 'gone']),
        ],
      );

      final read = source.read(
        createdAt: t0,
        settings: const AppSettings(),
        replayMonth: null,
      );

      expect(read.playlists.single.tracks, ['1']);
    });

    test('reads only the parts asked for, and the songs they name', () {
      store(
        tracks: [_track('1'), _track('2'), _track('3')],
        playlists: [
          playlist(Playlist.likesId, 'Liked', ['1']),
          playlist('p', 'Mix', ['2']),
        ],
        plays: [play('3', t0)],
      );

      final likes = source.read(
        createdAt: t0,
        settings: const AppSettings(),
        replayMonth: 5,
        parts: {BackupPart.likes},
      );

      expect(likes.parts, {BackupPart.likes});
      expect(likes.playlists.single.isLikes, isTrue);
      expect(likes.tracks.keys, ['1']);
      expect(likes.plays, isEmpty);
      expect(likes.replayMonth, isNull);
      expect(likes.settings, isNull);

      final history = source.read(
        createdAt: t0,
        settings: const AppSettings(),
        replayMonth: 5,
        parts: {BackupPart.history, BackupPart.playlists},
      );

      expect(history.playlists.single.name, 'Mix');
      expect(history.tracks.keys, unorderedEquals(['2', '3']));
      expect(history.plays.single.track, '3');
      expect(history.replayMonth, 5);
    });
  }, skip: skip);

  group('restoring some parts', () {
    test('a part left out keeps what this phone has', () async {
      store(
        playlists: [
          playlist(Playlist.likesId, 'Liked', ['1']),
        ],
      );
      final saved = backup(
        playlists: const [
          BackupPlaylist(name: 'Liked', isLikes: true, tracks: ['a']),
          BackupPlaylist(name: 'Mix', isLikes: false, tracks: ['b']),
        ],
        plays: [BackupPlay(track: 'a', at: t0)],
        days: const [BackupDay(day: 20385, plays: 4, listenedMs: 1000)],
      );

      await source.restore(saved.only({BackupPart.playlists}), {
        'a': '1',
        'b': '2',
      });

      expect(trackIdsOf('Liked'), ['1']);
      expect(trackIdsOf('Mix'), ['2']);
      expect(isar.playEventModels.count(), 0);
      expect(isar.listeningDayModels.count(), 0);
    });
  }, skip: skip);

  group('restoring', () {
    test('adds to the liked songs after the ones already there', () async {
      store(
        playlists: [
          playlist(Playlist.likesId, 'Liked', ['x']),
        ],
      );

      await source.restore(
        backup(
          playlists: const [
            BackupPlaylist(name: 'Liked', isLikes: true, tracks: ['a', 'b']),
          ],
        ),
        {'a': '1', 'b': 'x'},
      );

      final likes = isar.playlistModels
          .where()
          .playlistIdEqualTo(Playlist.likesId)
          .findFirst()!;
      expect(likes.trackIds, ['x', '1']);
    });

    test('creates the liked songs when there are none yet', () async {
      await source.restore(
        backup(
          playlists: const [
            BackupPlaylist(name: 'Liked', isLikes: true, tracks: ['a']),
          ],
        ),
        {'a': '1'},
      );

      final likes = isar.playlistModels
          .where()
          .playlistIdEqualTo(Playlist.likesId)
          .findFirst()!;
      expect(likes.trackIds, ['1']);
      expect(likes.name, IsarLibraryDataSource.likesPlaylistName);
    });

    test('joins a playlist of the same name, or creates it', () async {
      store(
        playlists: [
          playlist('p', 'Mix', ['x']),
        ],
      );

      await source.restore(
        backup(
          playlists: const [
            BackupPlaylist(name: 'Mix', isLikes: false, tracks: ['a']),
            BackupPlaylist(name: 'New', isLikes: false, tracks: ['b', 'c']),
          ],
        ),
        {'a': '1', 'b': '2'},
      );

      expect(trackIdsOf('Mix'), ['x', '1']);
      expect(trackIdsOf('New'), ['2']);
      expect(isar.playlistModels.count(), 2);
    });

    test('a second restore changes nothing', () async {
      store(
        playlists: [
          playlist(Playlist.likesId, 'Liked', ['x']),
        ],
      );
      final saved = backup(
        playlists: const [
          BackupPlaylist(name: 'Liked', isLikes: true, tracks: ['a', 'b']),
          BackupPlaylist(name: 'New', isLikes: false, tracks: ['a']),
        ],
        plays: [
          for (var i = 0; i < 5; i++)
            BackupPlay(
              track: 'a',
              at: t0.add(Duration(hours: i)),
            ),
        ],
        days: const [BackupDay(day: 10, plays: 2, listenedMs: 500)],
        trackDays: const [BackupTrackDay(day: 10, track: 'a', plays: 2)],
        firstPlays: const [BackupFirstPlay(track: 'b', day: 7)],
      );
      const ids = {'a': '1', 'b': '2'};

      String snapshot() => [
        for (final p in isar.playlistModels.where().sortById().findAll())
          '${p.playlistId}:${p.name}:${p.trackIds}',
        for (final e in isar.playEventModels.where().sortByPlayedAt().findAll())
          '${e.trackId}@${e.playedAt.millisecondsSinceEpoch}',
        for (final d in isar.listeningDayModels.where().findAll())
          '${d.id}:${d.plays}:${d.listenedMs}',
        for (final d in isar.trackDayModels.where().findAll())
          '${d.id}:${d.plays}',
        for (final f in isar.trackFirstPlayModels.where().findAll())
          '${f.id}:${f.day}',
      ].join('|');

      await source.restore(saved, ids);
      final once = snapshot();
      await source.restore(saved, ids);

      expect(snapshot(), once);
      expect(isar.playEventModels.count(), 3);
    });

    test('two playlists of one name stay two', () async {
      const saved = [
        BackupPlaylist(name: 'Mix', isLikes: false, tracks: ['a']),
        BackupPlaylist(name: 'Mix', isLikes: false, tracks: ['b']),
      ];

      await source.restore(backup(playlists: saved), {'a': '1', 'b': '2'});
      await source.restore(backup(playlists: saved), {'a': '1', 'b': '2'});

      final mixes = isar.playlistModels.where().sortById().findAll();
      expect(mixes.map((p) => p.trackIds), [
        ['1'],
        ['2'],
      ]);
    });

    test('a smart playlist comes back with its rules, once, and never '
        'merges with a playlist of songs of its name', () async {
      const rules = SmartRules(rules: [Liked(true)], limit: 25);
      store(
        playlists: [
          playlist('p', 'Mix', ['x']),
        ],
      );
      const saved = [
        BackupPlaylist(name: 'Mix', isLikes: false, tracks: [], rules: rules),
      ];

      await source.restore(backup(playlists: saved), const {});
      await source.restore(backup(playlists: saved), const {});

      final all = isar.playlistModels.where().sortById().findAll();
      expect(all, hasLength(2));
      expect(all.first.trackIds, ['x']);
      expect(all.first.rulesJson, isNull);
      expect(all.last.toEntity().rules, rules);
      expect(all.last.trackIds, isEmpty);
    });

    test('rules a backup holds but cannot be read never replace a smart '
        'playlist that works; with none here, they come as they are', () async {
      const working = SmartRules(rules: [Liked(true)]);
      store(
        playlists: [
          playlist('s', 'Auto', [])
            ..rulesJson = SmartRulesJson.encodeString(working),
        ],
      );
      const saved = [
        BackupPlaylist(
          name: 'Auto',
          isLikes: false,
          tracks: [],
          rules: SmartRulesJson.unreadable,
        ),
        BackupPlaylist(
          name: 'Other',
          isLikes: false,
          tracks: [],
          rules: SmartRulesJson.unreadable,
        ),
      ];

      await source.restore(backup(playlists: saved), const {});

      final all = isar.playlistModels.where().sortById().findAll();
      expect(all.map((p) => p.name), ['Auto', 'Other']);
      expect(all.first.toEntity().rules, working);
      expect(all.last.toEntity().rules, SmartRulesJson.unreadable);
    });

    test('a smart playlist is read into the backup with its rules', () {
      const rules = SmartRules(rules: [Liked(true)]);
      store(
        playlists: [
          playlist('s', 'Auto', [])
            ..rulesJson = SmartRulesJson.encodeString(rules),
        ],
      );
      final read = source.read(
        createdAt: t0,
        settings: const AppSettings(),
        replayMonth: null,
      );
      expect(read.playlists.single.rules, rules);
    });

    test('same names pair by rank with what was here, twice over', () async {
      store(
        playlists: [
          playlist('p', 'Mix', ['x']),
        ],
      );
      final saved = backup(
        playlists: const [
          BackupPlaylist(name: 'Mix', isLikes: false, tracks: ['a']),
          BackupPlaylist(name: 'Mix', isLikes: false, tracks: ['b']),
        ],
      );

      await source.restore(saved, {'a': '1', 'b': '2'});
      await source.restore(saved, {'a': '1', 'b': '2'});

      final mixes = isar.playlistModels.where().sortById().findAll();
      expect(mixes.map((p) => p.trackIds), [
        ['x', '1'],
        ['2'],
      ]);
    });

    test('a play already stored is not added again', () async {
      store(plays: [play('1', t0)]);

      await source.restore(
        backup(
          plays: [
            BackupPlay(track: 'a', at: t0.toUtc()),
            BackupPlay(track: 'b', at: t0),
          ],
        ),
        {'a': '1', 'b': '2'},
      );

      final plays = isar.playEventModels.where().findAll();
      expect(plays.map((p) => p.trackId), unorderedEquals(['1', '2']));
    });

    test('keeps the newest plays within the cap', () async {
      await source.restore(
        backup(
          plays: [
            for (var i = 0; i < 5; i++)
              BackupPlay(
                track: 'a',
                at: t0.add(Duration(hours: i)),
              ),
          ],
        ),
        {'a': '1'},
      );

      final plays = isar.playEventModels.where().sortByPlayedAt().findAll();
      expect(plays, hasLength(3));
      expect(plays.first.playedAt, t0.add(const Duration(hours: 2)));
    });

    test('daily totals keep the larger count', () async {
      isar.write(
        (isar) => isar.listeningDayModels.put(
          ListeningDayModel()
            ..id = 10
            ..plays = 5
            ..listenedMs = 100,
        ),
      );

      await source.restore(
        backup(days: const [BackupDay(day: 10, plays: 2, listenedMs: 900)]),
        const {},
      );

      final day = isar.listeningDayModels.get(10)!;
      expect(day.plays, 5);
      expect(day.listenedMs, 900);
    });

    test('hour totals keep the larger count, and are read back', () async {
      isar.write(
        (isar) => isar.listeningHourModels.putAll([
          ListeningHourModel()
            ..id = 240
            ..plays = 5,
          ListeningHourModel()
            ..id = 241
            ..plays = 1,
        ]),
      );

      await source.restore(
        backup(
          hours: const [
            BackupHour(hour: 240, plays: 2),
            BackupHour(hour: 241, plays: 4),
            BackupHour(hour: 300, plays: 3),
          ],
        ),
        const {},
      );

      expect(isar.listeningHourModels.get(240)!.plays, 5);
      expect(isar.listeningHourModels.get(241)!.plays, 4);
      expect(isar.listeningHourModels.get(300)!.plays, 3);
      final read = source.read(
        createdAt: t0,
        settings: const AppSettings(),
        replayMonth: null,
      );
      expect(read.hours, hasLength(3));
    });

    test('a backup without hours counts the plays it adds, once', () async {
      store(tracks: [_track('1')]);
      final old = backup(
        plays: [
          BackupPlay(track: 'a', at: t0.toUtc()),
          BackupPlay(
            track: 'a',
            at: t0.add(const Duration(minutes: 5)).toUtc(),
          ),
        ],
      );

      await source.restore(old, {'a': '1'});
      await source.restore(old, {'a': '1'});

      final id = ListeningDay.of(t0) * 24 + t0.hour;
      expect(isar.listeningHourModels.get(id)!.plays, 2);
      expect(isar.listeningHourModels.count(), 1);
    });

    test('plays pruned at once by the cap add no hours', () async {
      store(
        tracks: [_track('1')],
        plays: [
          for (var i = 1; i <= 3; i++) play('1', t0.add(Duration(days: i))),
        ],
      );
      final old = backup(
        plays: [
          BackupPlay(track: 'a', at: t0.toUtc()),
          BackupPlay(track: 'a', at: t0.add(const Duration(hours: 1)).toUtc()),
        ],
      );

      await source.restore(old, {'a': '1'});
      await source.restore(old, {'a': '1'});

      expect(isar.listeningHourModels.count(), 0);
      expect(isar.playEventModels.count(), 3);
    });

    test('two saved songs found as one add up their plays', () async {
      await source.restore(
        backup(
          trackDays: const [
            BackupTrackDay(day: 10, track: 'a', plays: 3),
            BackupTrackDay(day: 10, track: 'b', plays: 2),
          ],
        ),
        {'a': '1', 'b': '1'},
      );

      expect(isar.trackDayModels.get('10:1')!.plays, 5);
    });

    test('a first play keeps the earlier day', () async {
      isar.write(
        (isar) => isar.trackFirstPlayModels.putAll([
          TrackFirstPlayModel()
            ..id = '1'
            ..day = 50,
          TrackFirstPlayModel()
            ..id = '2'
            ..day = 5,
        ]),
      );

      await source.restore(
        backup(
          firstPlays: const [
            BackupFirstPlay(track: 'a', day: 20),
            BackupFirstPlay(track: 'b', day: 20),
          ],
        ),
        {'a': '1', 'b': '2'},
      );

      expect(isar.trackFirstPlayModels.get('1')!.day, 20);
      expect(isar.trackFirstPlayModels.get('2')!.day, 5);
    });

    test('songs not found are skipped everywhere', () async {
      await source.restore(
        backup(
          playlists: const [
            BackupPlaylist(name: 'New', isLikes: false, tracks: ['a', 'c']),
          ],
          plays: [BackupPlay(track: 'c', at: t0)],
          trackDays: const [BackupTrackDay(day: 1, track: 'c', plays: 1)],
          firstPlays: const [BackupFirstPlay(track: 'c', day: 1)],
        ),
        {'a': '1'},
      );

      expect(trackIdsOf('New'), ['1']);
      expect(isar.playEventModels.count(), 0);
      expect(isar.trackDayModels.count(), 0);
      expect(isar.trackFirstPlayModels.count(), 0);
    });

    group('imported lyrics', () {
      TrackLyricsModel row(String id, String? raw, String? source) =>
          TrackLyricsModel()
            ..id = id
            ..raw = raw
            ..source = source
            ..offsetMs = 200
            ..checkedAt = t0;

      test('are read with their song and timing; online ones are not', () {
        store(tracks: [_track('1'), _track('2'), _track('3')]);
        isar.write(
          (isar) => isar.trackLyricsModels.putAll([
            row('1', '[00:01.00]Mine', 'imported'),
            row('2', '[00:01.00]Found', 'online'),
            row('3', null, null),
          ]),
        );
        final read = source.read(
          createdAt: t0,
          settings: const AppSettings(),
          replayMonth: null,
        );
        expect(read.lyrics, const [
          BackupLyrics(track: '1', text: '[00:01.00]Mine', offsetMs: 200),
        ]);
        // The online ones are found again; the correction set on them by
        // hand is carried, alone. So is one still waiting for its lyrics
        // (a row with no text): the next backup must not lose it.
        expect(read.lyricsOffsets, const [
          BackupLyricsOffset(track: '2', offsetMs: 200),
          BackupLyricsOffset(track: '3', offsetMs: 200),
        ]);
        expect(read.tracks.keys, ['1', '2', '3']);
      });

      test('are left out, with their songs, when not asked for', () {
        store(tracks: [_track('1'), _track('2')]);
        isar.write(
          (isar) => isar.trackLyricsModels.putAll([
            row('1', '[00:01.00]Mine', 'imported'),
            row('2', '[00:01.00]Found', 'online'),
          ]),
        );

        final read = source.read(
          createdAt: t0,
          settings: const AppSettings(),
          replayMonth: null,
          parts: BackupPart.all.difference({BackupPart.lyrics}),
        );

        expect(read.parts, isNot(contains(BackupPart.lyrics)));
        expect(read.lyrics, isEmpty);
        expect(read.lyricsOffsets, isEmpty);
        expect(read.tracks, isEmpty);
      });

      test('a correction restored on a phone that never looked the lyrics '
          'up is still in its next backup', () async {
        store(tracks: [_track('1')]);
        final saved = backup();
        await source.restore(
          Backup(
            createdAt: saved.createdAt,
            tracks: saved.tracks,
            playlists: const [],
            plays: const [],
            days: const [],
            trackDays: const [],
            firstPlays: const [],
            replayMonth: null,
            settings: const AppSettings(),
            lyricsOffsets: const [
              BackupLyricsOffset(track: 'a', offsetMs: 300),
            ],
          ),
          {'a': '1'},
        );
        final again = source.read(
          createdAt: t0,
          settings: const AppSettings(),
          replayMonth: null,
        );
        expect(again.lyricsOffsets, const [
          BackupLyricsOffset(track: '1', offsetMs: 300),
        ]);
        expect(again.lyrics, isEmpty);
      });

      test('online lyrics never corrected carry nothing', () {
        store(tracks: [_track('1')]);
        isar.write(
          (isar) => isar.trackLyricsModels.put(
            row('1', '[00:01.00]Found', 'online')..offsetMs = 0,
          ),
        );
        final read = source.read(
          createdAt: t0,
          settings: const AppSettings(),
          replayMonth: null,
        );
        expect(read.lyricsOffsets, isEmpty);
        expect(read.tracks, isEmpty);
      });

      test('a correction of online lyrics comes back for the lyrics found '
          'here: kept for the first look, never over lyrics imported or '
          'corrected on this phone', () async {
        isar.write(
          (isar) => isar.trackLyricsModels.putAll([
            // Found here, not corrected: takes the correction.
            row('1', '[00:01.00]Found', 'online')..offsetMs = 0,
            // Corrected here: kept.
            row('2', '[00:01.00]Found', 'online')..offsetMs = -500,
            // Imported here: the correction was for other timings.
            row('3', '[00:01.00]Here', 'imported')..offsetMs = 0,
            // A miss remembered: takes it for the day lyrics are found,
            // and is asked again when it was going to be.
            row('4', null, null)..offsetMs = 0,
          ]),
        );
        final saved = backup();
        await source.restore(
          Backup(
            createdAt: saved.createdAt,
            tracks: saved.tracks,
            playlists: const [],
            plays: const [],
            days: const [],
            trackDays: const [],
            firstPlays: const [],
            replayMonth: null,
            settings: const AppSettings(),
            lyricsOffsets: const [
              BackupLyricsOffset(track: 'a', offsetMs: 300),
              BackupLyricsOffset(track: 'b', offsetMs: 300),
              BackupLyricsOffset(track: 'c', offsetMs: 300),
              BackupLyricsOffset(track: 'd', offsetMs: 300),
              BackupLyricsOffset(track: 'e', offsetMs: 300),
              BackupLyricsOffset(track: 'gone', offsetMs: 300),
            ],
          ),
          {'a': '1', 'b': '2', 'c': '3', 'd': '4', 'e': '5'},
        );
        final rows = isar.trackLyricsModels;
        expect(rows.get('1')!.offsetMs, 300);
        expect(rows.get('1')!.raw, '[00:01.00]Found');
        expect(rows.get('2')!.offsetMs, -500);
        expect(rows.get('3')!.offsetMs, 0);
        expect(rows.get('4')!.offsetMs, 300);
        expect(rows.get('4')!.raw, isNull);
        expect(rows.get('4')!.checkedAt, t0);
        // No lyrics yet: kept for the first look, which asks at once.
        final waiting = rows.get('5')!;
        expect(waiting.raw, isNull);
        expect(waiting.source, isNull);
        expect(waiting.offsetMs, 300);
        expect(waiting.checkedAt.millisecondsSinceEpoch, 0);
      });

      test('come back over online lyrics and misses, never over lyrics '
          'imported here', () async {
        isar.write(
          (isar) => isar.trackLyricsModels.putAll([
            row('1', '[00:01.00]Found', 'online'),
            row('2', null, null),
            row('3', '[00:01.00]Here', 'imported'),
          ]),
        );
        final saved = backup();
        await source.restore(
          Backup(
            createdAt: saved.createdAt,
            tracks: saved.tracks,
            playlists: const [],
            plays: const [],
            days: const [],
            trackDays: const [],
            firstPlays: const [],
            replayMonth: null,
            settings: const AppSettings(),
            lyrics: const [
              BackupLyrics(track: 'a', text: 'A', offsetMs: -100),
              BackupLyrics(track: 'b', text: 'B'),
              BackupLyrics(track: 'c', text: 'C'),
            ],
          ),
          {'a': '1', 'b': '2', 'c': '3'},
        );
        final rows = isar.trackLyricsModels;
        expect(rows.get('1')!.raw, 'A');
        expect(rows.get('1')!.source, 'imported');
        expect(rows.get('1')!.offsetMs, -100);
        expect(rows.get('2')!.raw, 'B');
        expect(rows.get('3')!.raw, '[00:01.00]Here');
      });
    });

    group('corrections', () {
      TrackEditModel edit(
        String id, {
        String? title,
        String? artist,
        String? year,
        String? cover,
      }) => TrackEditModel()
        ..id = isar.trackEditModels.autoIncrement()
        ..deviceId = id
        ..fileName = '$id.mp3'
        ..size = 42
        ..title = title
        ..artist = artist
        ..coverPath = cover
        ..editedAt = t0;

      Backup withEdits(List<BackupEdit> edits) {
        final saved = backup();
        return Backup(
          createdAt: saved.createdAt,
          tracks: saved.tracks,
          playlists: const [],
          plays: const [],
          days: const [],
          trackDays: const [],
          firstPlays: const [],
          replayMonth: null,
          settings: const AppSettings(),
          edits: edits,
        );
      }

      test('are read with their song described as its file says, never a '
          'picked cover alone', () {
        store(
          tracks: [
            _track('1')
              ..title = 'Mine'
              ..fileTitle = 'Title 1',
            _track('2'),
          ],
        );
        isar.write(
          (isar) => isar.trackEditModels.putAll([
            edit('1', title: 'Mine'),
            edit('2', cover: '/covers/a.png'),
          ]),
        );

        final read = source.read(
          createdAt: t0,
          settings: const AppSettings(),
          replayMonth: null,
        );

        expect(read.edits, const [BackupEdit(track: '1', title: 'Mine')]);
        expect(read.tracks.keys, ['1']);
        expect(read.tracks['1']!.title, 'Title 1', reason: 'the file\'s');

        final without = source.read(
          createdAt: t0,
          settings: const AppSettings(),
          replayMonth: null,
          parts: BackupPart.all.difference({BackupPart.edits}),
        );
        expect(without.edits, isEmpty);
        expect(without.tracks, isEmpty);
      });

      test('come back field by field, this phone\'s own winning, its cover '
          'kept, songs not found skipped', () async {
        store(tracks: [_track('1'), _track('2'), _track('4')]);
        isar.write(
          (isar) => isar.trackEditModels.put(
            edit('1', title: 'Here', cover: '/covers/here.png'),
          ),
        );

        final restored = withEdits(const [
          BackupEdit(track: 'a', title: 'Saved', artist: 'Chily'),
          BackupEdit(track: 'b', album: 'Doux', year: 2019),
          BackupEdit(track: 'c', title: 'Nowhere'),
          // What this phone's file already says: nothing to correct.
          BackupEdit(track: 'd', title: 'Title 4'),
        ]);
        await source.restore(restored, {
          'a': '1',
          'b': '2',
          'c': '3',
          'd': '4',
        });
        await source.restore(restored, {
          'a': '1',
          'b': '2',
          'c': '3',
          'd': '4',
        });

        final rows = {
          for (final e in isar.trackEditModels.where().findAll()) e.deviceId: e,
        };
        expect(rows.keys, unorderedEquals(['1', '2']), reason: 'once each');
        expect(
          rows['1']!.toEntity(),
          const TrackEdit(
            title: 'Here',
            artist: 'Chily',
            coverPath: '/covers/here.png',
          ),
        );
        expect(
          rows['2']!.toEntity(),
          const TrackEdit(album: 'Doux', year: 2019),
        );
        expect((rows['2']!.fileName, rows['2']!.size), ('2.mp3', 42));
      });
    });
  }, skip: skip);

  group('repository', () {
    late BackupRepositoryImpl repo;
    late Directory exports;

    setUp(() async {
      if (skip != null) return;
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      exports = Directory('${dir.path}/exports');
      repo = BackupRepositoryImpl(
        source: source,
        settings: SettingsRepositoryImpl(prefs),
        replayLog: SharedPrefsMonthlyReplayLog(prefs),
        exportDir: exports,
      );
    });

    test('a file over the limit is refused', () async {
      final file = File('${dir.path}/huge.json');
      final raf = await file.open(mode: FileMode.write);
      await raf.truncate(BackupCodec.maxBytes + 1);
      await raf.close();

      expect(await repo.readFile(file.path), isA<Left<Failure, Backup>>());
    });

    test('a damaged file comes back as a format failure', () async {
      final file = File('${dir.path}/bad.json')..writeAsStringSync('{"x":');

      expect(
        await repo.readFile(file.path),
        left<Failure, Backup>(const BackupFormatFailure('Not JSON')),
      );
    });

    test('an export reads back, and is deleted once cleared', () async {
      store(
        tracks: [_track('1')],
        playlists: [
          playlist(Playlist.likesId, 'Liked', ['1']),
        ],
      );

      final backup = (await repo.snapshot(
        BackupPart.all,
      )).getOrElse(() => throw StateError('no snapshot'));
      final path = (await repo.exportToFile(backup)).getOrElse(() => '');
      final read = await repo.readFile(path);
      await repo.clearExports();

      expect(read.isRight(), isTrue);
      expect(File(path).existsSync(), isFalse);
    });

    test('a backup of some parts reads back with those parts only', () async {
      store(
        tracks: [_track('1')],
        playlists: [
          playlist(Playlist.likesId, 'Liked', ['1']),
        ],
      );

      final backup = (await repo.snapshot({
        BackupPart.likes,
      })).getOrElse(() => throw StateError('no snapshot'));
      final path = (await repo.exportToFile(backup)).getOrElse(() => '');
      final read = (await repo.readFile(
        path,
      )).getOrElse(() => throw StateError('unreadable'));

      expect(backup.settings, isNull);
      expect(read.parts, {BackupPart.likes});
      expect(read.playlists.single.tracks, ['1']);
      expect(read.settings, isNull);
    });
  }, skip: skip);
}
