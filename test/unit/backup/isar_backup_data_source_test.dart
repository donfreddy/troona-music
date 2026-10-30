import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:troona/features/library/data/models/playlist_model.dart';
import 'package:troona/features/library/data/models/track_model.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
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

      final path = (await repo.exportToFile()).getOrElse(() => '');
      final read = await repo.readFile(path);
      await repo.clearExports();

      expect(read.isRight(), isTrue);
      expect(File(path).existsSync(), isFalse);
    });
  }, skip: skip);
}
