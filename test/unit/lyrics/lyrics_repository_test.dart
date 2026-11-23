import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/lyrics/data/models/track_lyrics_model.dart';
import 'package:troona/features/lyrics/data/repositories/lyrics_repository_impl.dart';
import 'package:troona/features/lyrics/data/sources/isar_lyrics_data_source.dart';
import 'package:troona/features/lyrics/data/sources/lyrics_query.dart';
import 'package:troona/features/lyrics/data/sources/lyrics_remote_source.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics_lookup.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/domain/repositories/settings_repository.dart';

import '../../helpers/fake_player.dart';
import '../../helpers/isar_host.dart';

class _Settings implements SettingsRepository {
  AppSettings? value;
  _Settings(this.value);

  @override
  Future<Either<Failure, AppSettings>> loadSettings() async =>
      value == null ? left(const CacheFailure('unreadable')) : right(value!);

  @override
  Future<Either<Failure, Unit>> saveSettings(AppSettings settings) async =>
      right(unit);

  @override
  Future<Either<Failure, Unit>> resetSettings() async => right(unit);
}

/// Answers [answer] (a text, null for none, or [LyricsUnreachable] to
/// throw), and counts the questions.
class _Remote implements LyricsRemoteSource {
  Object? answer;
  Completer<void>? gate;
  final asked = <LyricsQuery>[];

  @override
  Future<String?> find(LyricsQuery query) async {
    asked.add(query);
    await gate?.future;
    if (answer case final LyricsUnreachable e) throw e;
    return answer as String?;
  }
}

const _synced = '[00:01.00]First\n[00:03.00]Second';
const _plain = 'First\nSecond';

void main() {
  late Directory dir;
  late Isar isar;
  late IsarLyricsDataSource store;
  late _Settings settings;
  late _Remote lrclib;
  late _Remote ovh;
  late DateTime now;
  late LyricsRepositoryImpl repo;
  final track = testTrack('a', durationMs: 200000);

  final library = hostIsarLibrary();
  final skip = library == null
      ? 'No Isar core for ${Platform.operatingSystem}'
      : null;

  setUpAll(() async {
    if (library != null) await Isar.initialize(library);
  });

  setUp(() async {
    if (skip != null) return;
    dir = await Directory.systemTemp.createTemp('lyrics_repo_test');
    isar = Isar.open(
      schemas: IsarLyricsDataSource.schemas,
      directory: dir.path,
      inspector: false,
    );
    store = IsarLyricsDataSource(isar);
    settings = _Settings(const AppSettings(fetchLyrics: true));
    lrclib = _Remote();
    ovh = _Remote();
    now = DateTime(2026, 11, 22, 10);
    repo = LyricsRepositoryImpl(
      store: store,
      remotes: [lrclib, ovh],
      settings: settings,
      now: () => now,
    );
  });

  tearDown(() async {
    if (skip != null) return;
    isar.close(deleteFromDisk: true);
    await dir.delete(recursive: true);
  });

  group('switch off', () {
    test('asks no source, and offers to turn it on', () async {
      settings.value = const AppSettings();
      lrclib.answer = _synced;
      expect(
        await repo.lyricsFor(track),
        const LyricsMissing(onlineEnabled: false),
      );
      expect(lrclib.asked, isEmpty);
      expect(ovh.asked, isEmpty);
    });

    test('unreadable settings count as off', () async {
      settings.value = null;
      await repo.lyricsFor(track, searchAgain: true);
      expect(lrclib.asked, isEmpty);
    });

    test('imported lyrics still show', () async {
      settings.value = const AppSettings();
      await repo.import(track.id, utf8.encode(_synced));
      final found = await repo.lyricsFor(track) as LyricsFound;
      expect(found.lyrics.source, LyricsSource.imported);
    });

    test('remembers nothing: turning it on asks at once', () async {
      settings.value = const AppSettings();
      await repo.lyricsFor(track);
      settings.value = const AppSettings(fetchLyrics: true);
      lrclib.answer = _synced;
      expect(await repo.lyricsFor(track), isA<LyricsFound>());
    });
  });

  group('online', () {
    test('LRCLIB first; lyrics.ovh is not asked when it has some', () async {
      lrclib.answer = _synced;
      ovh.answer = _plain;
      final found = await repo.lyricsFor(track) as LyricsFound;
      expect(found.lyrics, isA<SyncedLyrics>());
      expect(found.lyrics.source, LyricsSource.online);
      expect(ovh.asked, isEmpty);
    });

    test('lyrics.ovh when LRCLIB has none', () async {
      ovh.answer = _plain;
      final found = await repo.lyricsFor(track) as LyricsFound;
      expect(found.lyrics, isA<PlainLyrics>());
      expect(lrclib.asked, hasLength(1));
    });

    test('the sources are told the title, artist, album and length', () async {
      await repo.lyricsFor(track);
      final q = lrclib.asked.single;
      expect(q.title, 'Title a');
      expect(q.artist, 'Artist');
      expect(q.album, 'Album');
      expect(q.duration, const Duration(seconds: 200));
    });

    test('synced lyrics found are kept for good', () async {
      lrclib.answer = _synced;
      await repo.lyricsFor(track);
      now = now.add(const Duration(days: 400));
      lrclib.answer = null;
      expect(await repo.lyricsFor(track), isA<LyricsFound>());
      expect(lrclib.asked, hasLength(1));
    });

    test('plain lyrics are asked for again after 30 days, kept if the '
        'sources have nothing better', () async {
      ovh.answer = _plain;
      await repo.lyricsFor(track);
      now = now.add(const Duration(days: 29));
      await repo.lyricsFor(track);
      expect(lrclib.asked, hasLength(1));

      now = now.add(const Duration(days: 2));
      ovh.answer = null;
      final found = await repo.lyricsFor(track) as LyricsFound;
      expect(found.lyrics, isA<PlainLyrics>());
      expect(lrclib.asked, hasLength(2));

      // Not asked again the next day: the look was remembered.
      now = now.add(const Duration(days: 1));
      await repo.lyricsFor(track);
      expect(lrclib.asked, hasLength(2));
    });

    test('nothing found is remembered for 30 days', () async {
      expect(
        await repo.lyricsFor(track),
        const LyricsMissing(onlineEnabled: true),
      );
      now = now.add(const Duration(days: 29));
      await repo.lyricsFor(track);
      expect(lrclib.asked, hasLength(1));
      expect(ovh.asked, hasLength(1));

      now = now.add(const Duration(days: 2));
      await repo.lyricsFor(track);
      expect(lrclib.asked, hasLength(2));
    });

    test('search again asks at once', () async {
      await repo.lyricsFor(track);
      lrclib.answer = _synced;
      expect(
        await repo.lyricsFor(track, searchAgain: true),
        isA<LyricsFound>(),
      );
      expect(lrclib.asked, hasLength(2));
    });

    test('unreachable: nothing remembered, the next look asks again', () async {
      lrclib.answer = const LyricsUnreachable('offline');
      ovh.answer = const LyricsUnreachable('offline');
      expect(
        await repo.lyricsFor(track),
        const LyricsMissing(onlineEnabled: true, unreachable: true),
      );
      expect(store.get(track.id), isNull);

      lrclib.answer = _synced;
      expect(await repo.lyricsFor(track), isA<LyricsFound>());
    });

    test('plain lyrics while LRCLIB is unreachable are kept for a day '
        'only: its synced ones may come next time', () async {
      lrclib.answer = const LyricsUnreachable('timeout');
      ovh.answer = _plain;
      expect(
        (await repo.lyricsFor(track) as LyricsFound).lyrics,
        isA<PlainLyrics>(),
      );
      now = now.add(const Duration(hours: 20));
      await repo.lyricsFor(track);
      expect(lrclib.asked, hasLength(1));

      now = now.add(const Duration(hours: 5));
      lrclib.answer = _synced;
      final found = await repo.lyricsFor(track) as LyricsFound;
      expect(found.lyrics, isA<SyncedLyrics>());
      expect(lrclib.asked, hasLength(2));
    });

    test('a miss while lyrics.ovh is unreachable is remembered for a '
        'day, not 30', () async {
      ovh.answer = const LyricsUnreachable('503');
      expect(
        await repo.lyricsFor(track),
        const LyricsMissing(onlineEnabled: true, unreachable: true),
      );
      now = now.add(const Duration(hours: 20));
      await repo.lyricsFor(track);
      expect(lrclib.asked, hasLength(1), reason: 'not asked on each look');

      now = now.add(const Duration(hours: 5));
      await repo.lyricsFor(track);
      expect(lrclib.asked, hasLength(2));
    });

    test('synced lyrics found while a source is unreachable are kept for '
        'good', () async {
      lrclib.answer = _synced;
      ovh.answer = const LyricsUnreachable('503');
      await repo.lyricsFor(track);
      now = now.add(const Duration(days: 400));
      await repo.lyricsFor(track);
      expect(lrclib.asked, hasLength(1));
    });

    test('turned off while LRCLIB is asked: lyrics.ovh is not, and '
        'nothing is written', () async {
      lrclib.gate = Completer();
      ovh.answer = _plain;
      final looking = repo.lyricsFor(track);
      await Future<void>.delayed(Duration.zero);
      settings.value = const AppSettings();
      lrclib.gate!.complete();
      await looking;
      expect(ovh.asked, isEmpty);
      expect(store.get(track.id), isNull);
    });

    test('a delete during a look wins: the answer is neither shown nor '
        'kept', () async {
      lrclib.gate = Completer();
      lrclib.answer = _synced;
      final looking = repo.lyricsFor(track);
      await Future<void>.delayed(Duration.zero);
      await repo.delete(track.id);
      lrclib.gate!.complete();
      expect(await looking, const LyricsMissing(onlineEnabled: true));
      expect(store.get(track.id)!.raw, isNull);
      expect(await repo.lyricsFor(track), isA<LyricsMissing>());
    });

    test('online lyrics count in the size of the online info, imported '
        'ones do not', () async {
      await repo.import(track.id, utf8.encode(_synced));
      expect(await repo.onlineSizeBytes(), 0);
      lrclib.answer = _synced;
      await repo.lyricsFor(testTrack('b', durationMs: 200000));
      expect(
        await repo.onlineSizeBytes(),
        greaterThanOrEqualTo(_synced.length),
      );
    });

    test('a text that holds no lyrics is a miss, the next source is '
        'asked', () async {
      lrclib.answer = '[ar:Someone]\n[ti:Song]';
      ovh.answer = _plain;
      expect(await repo.lyricsFor(track), isA<LyricsFound>());
      expect(ovh.asked, hasLength(1));
    });

    test('two looks at once ask once', () async {
      lrclib.gate = Completer();
      lrclib.answer = _synced;
      final first = repo.lyricsFor(track);
      final second = repo.lyricsFor(track);
      await Future<void>.delayed(Duration.zero);
      lrclib.gate!.complete();
      expect(await first, await second);
      expect(lrclib.asked, hasLength(1));
    });
  });

  group('import', () {
    test('wins over lyrics found online', () async {
      lrclib.answer = _synced;
      await repo.lyricsFor(track);
      final imported = await repo.import(
        track.id,
        utf8.encode('[00:02.00]Mine'),
      );
      expect(imported.isRight(), isTrue);
      final found = await repo.lyricsFor(track) as LyricsFound;
      expect(found.lyrics.source, LyricsSource.imported);
      expect((found.lyrics as SyncedLyrics).lines.single.text, 'Mine');
    });

    test('an online answer landing after an import does not replace '
        'it', () async {
      lrclib.gate = Completer();
      lrclib.answer = _synced;
      final looking = repo.lyricsFor(track);
      await Future<void>.delayed(Duration.zero);
      await repo.import(track.id, utf8.encode('[00:02.00]Mine'));
      lrclib.gate!.complete();

      final found = await looking as LyricsFound;
      expect(found.lyrics.source, LyricsSource.imported);
      expect(store.get(track.id)!.source, 'imported');
    });

    test('a file with no lyrics is refused, and keeps what was '
        'there', () async {
      await repo.import(track.id, utf8.encode(_plain));
      final result = await repo.import(track.id, utf8.encode('[ar:Someone]'));
      expect(result, left(const LyricsFormatFailure()));
      final found = await repo.lyricsFor(track) as LyricsFound;
      expect(found.lyrics, isA<PlainLyrics>());
    });

    test('a binary file is refused, even one with timestamps in '
        'it', () async {
      final bytes = [
        0xFF, 0xD8, 0xFF, 0xE0, 0, 0x10, //
        ...utf8.encode('[00:01.00]Hidden'),
        for (var i = 0; i < 200; i++) i % 32,
      ];
      expect(
        await repo.import(track.id, bytes),
        left(const LyricsFormatFailure()),
      );
      expect(store.get(track.id), isNull);
    });

    test('a file too big is refused', () async {
      final result = await repo.import(
        track.id,
        List.filled(512 * 1024 + 1, 0x61),
      );
      expect(result.isLeft(), isTrue);
      expect(store.get(track.id), isNull);
    });

    test('a new file starts its correction from zero', () async {
      await repo.import(track.id, utf8.encode(_synced));
      await repo.setOffset(track.id, const Duration(milliseconds: 300));
      await repo.import(track.id, utf8.encode(_synced));
      expect(
        (await repo.lyricsFor(track) as LyricsFound).offset,
        Duration.zero,
      );
    });
  });

  group('offset', () {
    test('is kept per song, and returned with its lyrics', () async {
      lrclib.answer = _synced;
      await repo.lyricsFor(track);
      await repo.setOffset(track.id, const Duration(milliseconds: -400));
      final found = await repo.lyricsFor(track) as LyricsFound;
      expect(found.offset, const Duration(milliseconds: -400));
    });

    test('survives a search again bringing the lyrics back', () async {
      lrclib.answer = _synced;
      await repo.lyricsFor(track);
      await repo.setOffset(track.id, const Duration(milliseconds: 200));
      final found =
          await repo.lyricsFor(track, searchAgain: true) as LyricsFound;
      expect(found.offset, const Duration(milliseconds: 200));
    });

    group('restored before any lyrics were found (a row with no text)', () {
      void waiting() => isar.write(
        (isar) => isar.trackLyricsModels.put(
          TrackLyricsModel()
            ..id = track.id
            ..offsetMs = 300
            ..checkedAt = DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );

      test('the first look asks at once, and the lyrics take it', () async {
        waiting();
        lrclib.answer = _synced;
        final found = await repo.lyricsFor(track) as LyricsFound;
        expect(lrclib.asked, hasLength(1));
        expect(found.offset, const Duration(milliseconds: 300));
      });

      test('nothing found: it waits on', () async {
        waiting();
        expect(await repo.lyricsFor(track), isA<LyricsMissing>());
        expect(isar.trackLyricsModels.get(track.id)!.offsetMs, 300);
      });

      test('switch off: no source is asked, and it waits on', () async {
        waiting();
        settings.value = const AppSettings();
        lrclib.answer = _synced;
        expect(
          await repo.lyricsFor(track),
          const LyricsMissing(onlineEnabled: false),
        );
        expect(lrclib.asked, isEmpty);
        expect(isar.trackLyricsModels.get(track.id)!.offsetMs, 300);
      });
    });

    test('is clamped to 10 s either way', () async {
      await repo.import(track.id, utf8.encode(_synced));
      await repo.setOffset(track.id, const Duration(seconds: 30));
      expect(
        (await repo.lyricsFor(track) as LyricsFound).offset,
        const Duration(seconds: 10),
      );
    });

    test('a song with no lyrics takes none', () async {
      expect(
        (await repo.setOffset(track.id, const Duration(seconds: 1))).isLeft(),
        isTrue,
      );
    });
  });

  group('delete', () {
    test('forgets the lyrics; online ones come back only on search '
        'again', () async {
      lrclib.answer = _synced;
      await repo.lyricsFor(track);
      await repo.delete(track.id);
      expect(
        await repo.lyricsFor(track),
        const LyricsMissing(onlineEnabled: true),
      );
      expect(lrclib.asked, hasLength(1));
      expect(
        await repo.lyricsFor(track, searchAgain: true),
        isA<LyricsFound>(),
      );
    });

    test('removes imported lyrics too', () async {
      settings.value = const AppSettings();
      await repo.import(track.id, utf8.encode(_synced));
      await repo.delete(track.id);
      expect(
        await repo.lyricsFor(track),
        const LyricsMissing(onlineEnabled: false),
      );
    });
  });

  test('clearing the online info keeps the imported lyrics', () async {
    final other = testTrack('b', durationMs: 200000);
    final missing = testTrack('c', durationMs: 200000);
    await repo.import(track.id, utf8.encode(_synced));
    lrclib.answer = _synced;
    await repo.lyricsFor(other);
    lrclib.answer = null;
    await repo.lyricsFor(missing);

    await repo.clearOnline();
    expect(store.get(track.id)!.source, 'imported');
    expect(store.get(other.id), isNull);
    expect(store.get(missing.id), isNull);
  });
}
