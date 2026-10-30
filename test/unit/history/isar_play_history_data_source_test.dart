import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_plus/isar_plus.dart';
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
      expect(source.activeDays(day - 1, day + 2), {day, day + 1});
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
      expect(source.activeDays(day, day + 1), isEmpty);
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

      await source.backfillDays();
      await source.backfillDays();

      final stats = source.listeningStats(day - 2, day);
      expect(stats.plays, 3);
      expect(stats.discoveries, 3);
      expect(stats.historyStart, day - 2);
    }, skip: skip);
  });
}
