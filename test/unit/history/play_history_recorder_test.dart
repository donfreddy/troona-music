import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/history/domain/entities/play_event.dart';
import 'package:troona/features/history/domain/repositories/play_history_repository.dart';
import 'package:troona/features/history/domain/use_cases/record_play_use_case.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/services/history/play_history_recorder.dart';

import '../../helpers/fake_player.dart';

final class _MemoryHistory implements PlayHistoryRepository {
  final events = <PlayEvent>[];

  @override
  Future<Either<Failure, Unit>> record(PlayEvent event) async {
    events.add(event);
    return right(unit);
  }

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<Either<Failure, List<String>>> recentTrackIds({
    required int limit,
  }) async => right([]);
}

void main() {
  final a = testTrack('a', durationMs: 240000);
  final b = testTrack('b', durationMs: 240000);
  final at = DateTime(2026, 10, 24, 9);

  late FakeAudioPort port;
  late _MemoryHistory history;
  late PlayHistoryRecorder recorder;

  setUp(() {
    port = FakeAudioPort();
    history = _MemoryHistory();
    recorder = PlayHistoryRecorder(
      port: port,
      recordPlay: RecordPlayUseCase(history),
      now: () => at,
    );
  });

  tearDown(() async {
    await recorder.dispose();
    await port.close();
  });

  /// The adapter emits its queue once a new one is loaded.
  void playing(List<Track> tracks, {int index = 0}) =>
      port.queueCtrl.add(Queue.fromTracks(tracks, startIndex: index));

  /// Playback from [fromS] to [toS] seconds in 200 ms ticks.
  void listen(int fromS, int toS) {
    for (var ms = fromS * 1000; ms <= toS * 1000; ms += 200) {
      port.position.add(Duration(milliseconds: ms));
    }
  }

  test('records a track once it has been listened to for 30 s', () async {
    recorder.start();
    playing([a]);

    listen(0, 29);
    expect(history.events, isEmpty);
    listen(30, 60);
    await pumpEventQueue();

    expect(history.events.map((e) => (e.trackId, e.playedAt)), [('a', at)]);
  });

  test('counts the track already loaded when it starts', () async {
    port.queue = Queue.fromTracks([a], startIndex: 0);
    recorder.start();

    listen(0, 31);
    await pumpEventQueue();

    expect(history.events.single.trackId, 'a');
  });

  test('a re-emitted current track does not restart the listen', () async {
    recorder.start();
    playing([a]);

    listen(0, 20);
    playing([a]); // a queue edit re-emits the queue
    listen(20, 31);
    await pumpEventQueue();

    expect(history.events.single.trackId, 'a');
  });

  test('skipping before 30 s records nothing for that track', () async {
    recorder.start();
    playing([a]);
    listen(0, 10);
    playing([b]);
    listen(0, 31);
    await pumpEventQueue();

    expect(history.events.map((e) => e.trackId), ['b']);
  });

  test('a stale index while a new queue loads is not a track', () async {
    recorder.start();
    playing([a, b]);
    // Loading [x]: the player index is read against the old queue first.
    port.track.add(b);
    listen(0, 1);
    final x = testTrack('x', durationMs: 240000);
    playing([x]);
    listen(1, 31);
    await pumpEventQueue();

    expect(history.events.map((e) => e.trackId), ['x']);
  });

  test('shuffling mid-track keeps the listen going', () async {
    recorder.start();
    final queue = Queue.fromTracks([a, b], startIndex: 0);
    port.queueCtrl.add(queue);
    listen(0, 20);
    port.queueCtrl.add(queue.toggleShuffle());
    listen(20, 31);
    await pumpEventQueue();

    expect(history.events.single.trackId, 'a');
  });

  test('stops listening once disposed', () async {
    recorder.start();
    playing([a]);
    await recorder.dispose();

    listen(0, 31);
    await pumpEventQueue();

    expect(history.events, isEmpty);
  });
}
