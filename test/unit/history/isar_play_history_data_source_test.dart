import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:troona/features/history/data/models/play_event_model.dart';
import 'package:troona/features/history/data/sources/isar_play_history_data_source.dart';

/// The Isar core shipped for the host OS by isar_plus_flutter_libs, found
/// through the package config (`flutter test` runs from the project root).
String? _hostIsarLibrary() {
  final file = switch (Platform.operatingSystem) {
    'macos' => 'macos/libisar.dylib',
    'linux' => 'linux/libisar.so',
    _ => null,
  };
  final config = File('.dart_tool/package_config.json');
  if (file == null || !config.existsSync()) return null;
  final packages = (jsonDecode(config.readAsStringSync()) as Map)['packages'];
  for (final package in packages as List) {
    if (package['name'] != 'isar_plus_flutter_libs') continue;
    final root = config.uri.resolve('${package['rootUri']}/');
    final path = root.resolve(file).toFilePath();
    return File(path).existsSync() ? path : null;
  }
  return null;
}

void main() {
  late Directory dir;
  late Isar isar;
  late IsarPlayHistoryDataSource source;
  final t0 = DateTime(2026, 10, 24, 9);

  final library = _hostIsarLibrary();
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
}
