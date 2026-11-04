import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:troona/features/history/data/models/listening_models.dart';
import 'package:troona/features/history/data/models/play_event_model.dart';
import 'package:troona/features/history/data/sources/isar_play_history_data_source.dart';
import 'package:troona/features/history/domain/listening_day.dart';

import '../../helpers/isar_host.dart';

void main() {
  late Directory dir;
  late Isar isar;
  late IsarPlayHistoryDataSource source;
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
    dir = await Directory.systemTemp.createTemp('play_history_test');
    isar = Isar.open(
      schemas: IsarPlayHistoryDataSource.schemas,
      directory: dir.path,
      inspector: false,
    );
    source = IsarPlayHistoryDataSource(isar, maxEvents: 5);
  });

  tearDown(() async {
    if (skip != null) return;
    isar.close(deleteFromDisk: true);
    await dir.delete(recursive: true);
  });

  Future<void> play(String id, int minute) => source.add(
    PlayEventModel()
      ..trackId = id
      ..playedAt = t0.add(Duration(minutes: minute)),
  );

  test('recent ids: most recent first, each track once', () async {
    await play('a', 0);
    await play('b', 1);
    await play('a', 2);
    await play('c', 3);

    expect(await source.recentTrackIds(limit: 10), ['c', 'a', 'b']);
    expect(await source.recentTrackIds(limit: 2), ['c', 'a']);
  }, skip: skip);

  test('keeps only the newest events beyond the cap', () async {
    for (var i = 0; i < 7; i++) {
      await play('t$i', i);
    }

    expect(isar.playEventModels.count(), 5);
    expect(await source.recentTrackIds(limit: 10), [
      't6',
      't5',
      't4',
      't3',
      't2',
    ]);
  }, skip: skip);

  test('watch fires once per recorded play, pruning included', () async {
    var changes = 0;
    final sub = source.watch().listen((_) => changes++);
    for (var i = 0; i < 6; i++) {
      await play('t$i', i);
    }
    await pumpEventQueue();
    await sub.cancel();

    expect(changes, 6);
  }, skip: skip);

  test('prunes by play time, not insertion order', () async {
    // A late write of an older play (clock change) is the one dropped.
    for (var i = 1; i <= 5; i++) {
      await play('t$i', i);
    }
    await play('old', 0);

    expect(await source.recentTrackIds(limit: 10), isNot(contains('old')));
    expect(isar.playEventModels.count(), 5);
  }, skip: skip);

  group('hourly totals', () {
    final day = ListeningDay.of(t0);

    test('count each play in its local hour and weekday', () async {
      await play('a', 0); // Saturday 9:00
      await play('b', 59); // 9:59
      await play('c', 60); // 10:00
      await play('d', 24 * 60 + 15 * 60); // Monday 0:00

      final stats = source.listeningStats(day, day + 2);
      final saturday = (DateTime.saturday - 1) * 24;
      expect(stats.hourPlays, hasLength(168));
      expect(stats.hourPlays[saturday + 9], 2);
      expect(stats.hourPlays[saturday + 10], 1);
      expect(stats.hourPlays[0], 1, reason: 'Monday at midnight');
      expect(
        source.listeningStats(day, day).hourPlays.fold(0, (a, b) => a + b),
        3,
      );
    }, skip: skip);

    test('outlive the pruned events', () async {
      for (var i = 0; i < 7; i++) {
        await play('t$i', i);
      }
      final stats = source.listeningStats(day, day);
      expect(stats.hourPlays[(t0.weekday - 1) * 24 + 9], 7);
    }, skip: skip);
  });

  group('daily totals', () {
    final day = ListeningDay.of(t0);

    test('outlive the pruned events', () async {
      for (var i = 0; i < 7; i++) {
        await play('t$i', i);
      }

      expect(isar.playEventModels.count(), 5);
      expect(source.listeningStats(day, day).plays, 7);
    }, skip: skip);

    test('count plays per track, and a replay is no new discovery', () async {
      await play('a', 0);
      await play('a', 5);
      await play('b', 10);

      final stats = source.listeningStats(day, day);
      expect(stats.trackPlays, {'a': 2, 'b': 1});
      expect(stats.discoveries, 2);
    }, skip: skip);

    test('play counts add up all days, for the tracks asked only', () async {
      await play('a', 0);
      await play('a', 60 * 24 + 1); // the next day
      await play('b', 5);
      await play('c', 6);

      expect(source.playCounts({'a', 'b', 'never'}), {'a': 2, 'b': 1});
      expect(source.playCounts({}), isEmpty);
    }, skip: skip);

    test('a track first played on an earlier day is no discovery', () async {
      await play('a', 0);
      await play('a', 24 * 60);
      await play('b', 24 * 60);

      expect(source.listeningStats(day + 1, day + 1).discoveries, 1);
      expect(source.listeningStats(day, day + 1).discoveries, 2);
      expect(source.listeningStats(day + 1, day + 1).historyStart, day);
    }, skip: skip);

    test('plays either side of midnight land on their own day', () async {
      final late = DateTime(2026, 10, 24, 23, 59);
      for (final at in [late, late.add(const Duration(minutes: 2))]) {
        await source.add(
          PlayEventModel()
            ..trackId = 'a'
            ..playedAt = at,
        );
      }

      expect(source.listeningStats(day, day).plays, 1);
      expect(source.listeningStats(day + 1, day + 1).plays, 1);
      expect(source.listeningStats(day - 1, day + 2).dayPlays, {
        day: 1,
        day + 1: 1,
      });
    }, skip: skip);

    test('listening time adds up per day', () async {
      await source.addListening(day, 30000);
      await source.addListening(day, 12500);
      await source.addListening(day + 1, 1000);

      expect(
        source.listeningStats(day, day).listened,
        const Duration(milliseconds: 42500),
      );
      // Listening alone is not a play: the day stays off the calendar.
      expect(source.listeningStats(day, day + 1).dayPlays, isEmpty);
    }, skip: skip);

    test('backfill counts the stored events once', () async {
      isar.write((isar) {
        for (var i = 0; i < 3; i++) {
          isar.playEventModels.put(
            PlayEventModel()
              ..id = i + 1
              ..trackId = 'old$i'
              ..playedAt = t0.subtract(Duration(days: i)),
          );
        }
      });

      await source.backfill();
      await source.backfill();

      final stats = source.listeningStats(day - 2, day);
      expect(stats.plays, 3);
      expect(stats.discoveries, 3);
      expect(stats.historyStart, day - 2);
      // Three days at 9: one play at 9 on each of their weekdays.
      expect(stats.hourPlays.where((p) => p > 0), [1, 1, 1]);
      expect(stats.hourPlays[(t0.weekday - 1) * 24 + 9], 1);
    }, skip: skip);

    test('backfill fills the hours alone when the days exist', () async {
      // An update from a version that kept days but no hours.
      await play('a', 0);
      isar.write((isar) => isar.listeningHourModels.clear());
      isar.write(
        (isar) => isar.playEventModels.put(
          PlayEventModel()
            ..id = 100
            ..trackId = 'b'
            ..playedAt = t0.add(const Duration(hours: 3)),
        ),
      );

      await source.backfill();

      final stats = source.listeningStats(day, day);
      expect(stats.plays, 1, reason: 'the days are not counted twice');
      final base = (t0.weekday - 1) * 24;
      expect(stats.hourPlays[base + 9], 1);
      expect(stats.hourPlays[base + 12], 1);
    }, skip: skip);
  });
}
