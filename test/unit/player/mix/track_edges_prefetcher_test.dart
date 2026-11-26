import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/track_edges.dart';
import 'package:troona/features/player/domain/repositories/track_edges_repository.dart';
import 'package:troona/services/mix/track_edges_prefetcher.dart';

import '../../../helpers/fake_player.dart';

final class _Repository implements TrackEdgesRepository {
  final asked = <String>[];

  /// Holds each analysis until completed, by song id.
  final held = <String, Completer<TrackEdges?>>{};

  @override
  Future<TrackEdges?> edgesOf(Track track) {
    asked.add(track.id);
    return (held[track.id] = Completer<TrackEdges?>()).future;
  }

  void finish(String id, [TrackEdges? edges = _edges]) =>
      held[id]!.complete(edges);
}

const _edges = TrackEdges(
  musicStart: Duration.zero,
  musicEnd: Duration(seconds: 190),
);

void main() {
  final tracks = [
    for (final id in 'abcd'.split('')) testTrack(id, durationMs: 200000),
  ];
  final [a, b, c, _] = tracks;

  late FakeAudioPort port;
  late _Repository repository;
  late bool wanted;
  late DateTime now;
  late TrackEdgesPrefetcher prefetcher;

  setUp(() {
    port = FakeAudioPort();
    repository = _Repository();
    wanted = true;
    now = DateTime(2026, 11, 26, 12);
    prefetcher = TrackEdgesPrefetcher(
      port: port,
      repository: repository,
      wanted: () => wanted,
      now: () => now,
    )..start();
  });

  tearDown(() => prefetcher.stop());

  void play(int index) =>
      port.queueCtrl.add(Queue.fromTracks(tracks, startIndex: index));

  test('the song playing first, then the next, one at a time', () async {
    play(0);
    await pumpEventQueue();
    expect(repository.asked, ['a']);

    repository.finish('a');
    await pumpEventQueue();
    expect(repository.asked, ['a', 'b']);
    expect(prefetcher.edgesOf(a), _edges);
    expect(prefetcher.edgesOf(b), isNull);

    repository.finish('b');
    await pumpEventQueue();
    expect(prefetcher.edgesOf(b), _edges);
  });

  test('a song already known is not asked again', () async {
    play(0);
    await pumpEventQueue();
    repository.finish('a');
    await pumpEventQueue();
    repository.finish('b');
    await pumpEventQueue();

    play(1);
    await pumpEventQueue();
    expect(repository.asked, ['a', 'b', 'c']);
  });

  test('a song change drops the songs no longer due', () async {
    play(0);
    await pumpEventQueue();
    // While "a" is analysed, the queue moves on to "c".
    play(2);
    await pumpEventQueue();
    repository.finish('a');
    await pumpEventQueue();
    expect(repository.asked, ['a', 'c']);
    expect(prefetcher.edgesOf(c), isNull);
  });

  test('nothing is analysed while not wanted', () async {
    wanted = false;
    play(0);
    await pumpEventQueue();
    expect(repository.asked, isEmpty);
  });

  test('a song whose edges were not found stays unknown, and is asked '
      'again only after a while', () async {
    play(0);
    await pumpEventQueue();
    repository.finish('a', null);
    await pumpEventQueue();
    expect(prefetcher.edgesOf(a), isNull);
    repository.finish('b');
    await pumpEventQueue();

    // A pause publishes the queue again.
    play(0);
    await pumpEventQueue();
    expect(repository.asked, ['a', 'b']);

    now = now.add(TrackEdgesPrefetcher.retryAfter);
    play(0);
    await pumpEventQueue();
    expect(repository.asked, ['a', 'b', 'a']);
  });

  test('a failed analysis does not stop the next', () async {
    play(0);
    await pumpEventQueue();
    repository.held['a']!.completeError(StateError('decoder busy'));
    await pumpEventQueue();
    expect(repository.asked, ['a', 'b']);
  });
}
