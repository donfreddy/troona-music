import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';
import 'package:troona/features/library/data/models/track_model.dart';
import 'package:troona/services/scanner/artwork_extractor.dart';

/// Answers each artwork query when the test completes its gate.
class _GatedQuery extends Fake implements OnAudioQuery {
  final Map<int, Completer<Uint8List?>> gates = {};
  int running = 0;
  int maxRunning = 0;

  @override
  Future<Uint8List?> queryArtwork(
    int id,
    ArtworkType type, {
    ArtworkFormat? format,
    int? size,
    int? quality,
  }) async {
    running++;
    if (running > maxRunning) maxRunning = running;
    try {
      return await (gates[id] = Completer<Uint8List?>()).future;
    } finally {
      running--;
    }
  }
}

TrackModel _track(int id) => TrackModel()..deviceId = '$id';

/// Waits for [ready]: the extractor touches the disk (a cached cover is
/// looked for, a found one written), and `pumpEventQueue` turns the event
/// loop a fixed number of times, which a slow runner's disk can outlast.
Future<void> _until(bool Function() ready, String what) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (!ready()) {
    if (DateTime.now().isAfter(deadline)) fail('Timed out waiting for $what');
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late Directory dir;
  late _GatedQuery query;
  late ArtworkExtractor extractor;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('artwork_test');
    query = _GatedQuery();
    extractor = ArtworkExtractor(query: query, cacheDir: dir);
  });

  tearDown(() => dir.delete(recursive: true));

  test('streams results while later tracks still wait for a slot', () async {
    final results = <ArtworkResult>[];
    final done = Completer<void>();
    extractor
        .extractArtworks([for (var i = 1; i <= 6; i++) _track(i)])
        .listen(results.add, onDone: done.complete);
    await _until(() => query.gates.length == 4, 'four slots');
    // Settled: no fifth query starts while the four wait. Which four start
    // first depends on the cache checks before them, real file reads that
    // may end in any order.
    await pumpEventQueue();
    expect(query.gates, hasLength(4), reason: 'four slots');

    final first = query.gates.keys.first;
    final waiting = query.gates.keys.skip(1).toList();
    query.gates[first]!.complete(Uint8List.fromList([1, 2, 3]));
    await _until(() => results.isNotEmpty, 'the first cover written');
    expect(results.map((r) => r.deviceId), ['$first']);
    await _until(() => query.gates.length == 5, 'the slot handed over');
    for (final id in waiting) {
      expect(query.gates[id]!.isCompleted, isFalse, reason: 'still waiting');
    }

    for (final id in query.gates.keys.skip(1).toList()) {
      query.gates[id]!.complete(null);
    }
    await _until(() => query.gates.length == 6, 'the last track');
    final last = query.gates.keys.last;
    query.gates[last]!.completeError(StateError('decoder'));
    await done.future;

    expect(query.maxRunning, 4);
    final byId = {for (final r in results) r.deviceId: r};
    expect(byId['$first']!.artworkPath, '${dir.path}/$first.jpg');
    expect(byId['$first']!.checked, isTrue);
    final empty = waiting.first;
    expect(byId['$empty']!.artworkPath, isNull);
    expect(byId['$empty']!.checked, isTrue, reason: 'no cover is an answer');
    expect(
      byId['$last']!.checked,
      isFalse,
      reason: 'an error is retried later',
    );
  });

  test('a cached file short-circuits the platform query', () async {
    await File('${dir.path}/7.jpg').writeAsBytes([1]);
    final results = await extractor.extractArtworks([_track(7)]).toList();
    expect(query.gates, isEmpty);
    expect(results.single.artworkPath, '${dir.path}/7.jpg');
  });

  test('a cache folder the system deleted is made again', () async {
    await dir.delete(recursive: true);
    final results = <ArtworkResult>[];
    final done = Completer<void>();
    extractor
        .extractArtworks([_track(8)])
        .listen(results.add, onDone: done.complete);
    await _until(() => query.gates.containsKey(8), 'the query');
    query.gates[8]!.complete(Uint8List.fromList([1]));
    await done.future;

    expect(results.single.checked, isTrue);
    expect(File('${dir.path}/8.jpg').existsSync(), isTrue);
  });

  test('an empty list closes the stream', () async {
    expect(await extractor.extractArtworks([]).toList(), isEmpty);
  });
}
