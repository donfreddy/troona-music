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
    await pumpEventQueue();

    expect(query.gates.keys, [1, 2, 3, 4], reason: 'four slots');
    query.gates[1]!.complete(Uint8List.fromList([1, 2, 3]));
    await pumpEventQueue();

    expect(results.map((r) => r.deviceId), ['1']);
    expect(query.gates.keys, contains(5), reason: 'slot handed over');

    for (final id in [2, 3, 4, 5]) {
      query.gates[id]!.complete(null);
      await pumpEventQueue();
    }
    query.gates[6]!.completeError(StateError('decoder'));
    await done.future;

    expect(query.maxRunning, 4);
    final byId = {for (final r in results) r.deviceId: r};
    expect(byId['1']!.artworkPath, '${dir.path}/1.jpg');
    expect(byId['1']!.checked, isTrue);
    expect(byId['2']!.artworkPath, isNull);
    expect(byId['2']!.checked, isTrue, reason: 'no cover is an answer');
    expect(byId['6']!.checked, isFalse, reason: 'an error is retried later');
  });

  test('a cached file short-circuits the platform query', () async {
    await File('${dir.path}/7.jpg').writeAsBytes([1]);
    final results = await extractor.extractArtworks([_track(7)]).toList();
    expect(query.gates, isEmpty);
    expect(results.single.artworkPath, '${dir.path}/7.jpg');
  });

  test('an empty list closes the stream', () async {
    expect(await extractor.extractArtworks([]).toList(), isEmpty);
  });
}
