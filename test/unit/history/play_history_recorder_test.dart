import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/history/domain/entities/play_event.dart';
import 'package:troona/features/history/domain/repositories/play_history_repository.dart';
import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/history/domain/use_cases/record_listening_use_case.dart';
import 'package:troona/features/history/domain/use_cases/record_play_use_case.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/services/history/play_history_recorder.dart';

import '../../helpers/fake_player.dart';

final class _MemoryHistory implements PlayHistoryRepository {
  final events = <PlayEvent>[];
  final listening = <int, Duration>{};

  @override
  Future<Either<Failure, Unit>> recordListening(
    int day,
    Duration listened,
  ) async {
    listening[day] = (listening[day] ?? Duration.zero) + listened;
    return right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

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

  @override
  Future<Either<Failure, Map<String, int>>> topTrackIds({
    int days = 7,
    int limit = 5,
  }) async => right({});

  @override
  Future<Either<Failure, List<String>>> forgottenTrackIds(
    Set<String> likedIds, {
    int staleDays = 14,
    int limit = 5,
  }) async => right([]);
}

void main() {
  final a = testTrack('a', durationMs: 240000);
  final b = testTrack('b', durationMs: 240000);
  var at = DateTime(2026, 10, 24, 9);

  late FakeAudioPort port;
  late _MemoryHistory history;
  late PlayHistoryRecorder recorder;
  var paused = false;

  setUp(() {
    at = DateTime(2026, 10, 24, 9);
    paused = false;
    port = FakeAudioPort();
    history = _MemoryHistory();
    recorder = PlayHistoryRecorder(
      port: port,
      recordPlay: RecordPlayUseCase(history),
      recordListening: RecordListeningUseCase(history),
      now: () => at,
      paused: () => paused,
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

  group('listening time', () {
    int dayOf(DateTime t) => ListeningDay.of(t);

    test('is written every 30 s of listening', () async {
      recorder.start();
      playing([a]);

      listen(0, 29);
      await pumpEventQueue();
      expect(history.listening, isEmpty, reason: 'kept in memory until 30 s');

      listen(29, 60);
      await pumpEventQueue();
      expect(history.listening, {dayOf(at): const Duration(seconds: 60)});
    });

    test('a seek forward adds no time', () async {
      recorder.start();
      playing([a]);

      listen(0, 10);
      listen(100, 110);
      await recorder.dispose();
      await pumpEventQueue();

      expect(history.listening, {dayOf(at): const Duration(seconds: 20)});
    });

    test('a track change writes what was heard', () async {
      recorder.start();
      playing([a]);
      listen(0, 10);
      playing([b]);
      await pumpEventQueue();

      expect(history.listening, {dayOf(at): const Duration(seconds: 10)});
    });

    test('listening across midnight counts on both days', () async {
      at = DateTime(2026, 10, 24, 23, 59, 50);
      final first = dayOf(at);
      recorder.start();
      playing([a]);

      listen(0, 10);
      at = DateTime(2026, 10, 25, 0, 0, 1);
      listen(10, 25);
      await recorder.dispose();
      await pumpEventQueue();

      expect(history.listening, {
        first: const Duration(seconds: 10),
        first + 1: const Duration(seconds: 15),
      });
    });

    test('plays still count once time is being written', () async {
      recorder.start();
      playing([a]);
      listen(0, 65);
      await pumpEventQueue();

      expect(history.events.single.trackId, 'a');
    });
  });

  group('paused history', () {
    int dayOf(DateTime t) => ListeningDay.of(t);

    test('records neither plays nor listening time', () async {
      paused = true;
      recorder.start();
      playing([a]);
      listen(0, 65);
      playing([b]);
      listen(0, 65);
      await recorder.dispose();
      await pumpEventQueue();

      expect(history.events, isEmpty);
      expect(history.listening, isEmpty);
    });

    test('a listen begun before keeps what was heard then', () async {
      recorder.start();
      playing([a]);
      listen(0, 20);
      paused = true;
      listen(20, 40);
      paused = false;
      listen(40, 52);
      await recorder.dispose();
      await pumpEventQueue();

      // 20 s before, 12 s after: the play counts at 30 s heard, later.
      expect(history.events.single.trackId, 'a');
      expect(history.listening, {dayOf(at): const Duration(seconds: 32)});
    });

    test('playback during the pause never counts toward a listen', () async {
      recorder.start();
      playing([a]);
      listen(0, 20);
      paused = true;
      listen(20, 40);
      paused = false;
      listen(40, 49);
      await pumpEventQueue();

      expect(history.events, isEmpty, reason: '29 s heard while recording');
    });

    test('a replay from the top during the pause starts a new listen', () async {
      recorder.start();
      playing([a]);
      listen(0, 29);
      paused = true;
      listen(0, 120); // the same song again: the queue keeps its id
      paused = false;
      listen(120, 125);
      await pumpEventQueue();
      expect(history.events, isEmpty, reason: '5 s heard since the replay');

      listen(125, 150);
      await pumpEventQueue();
      expect(history.events.single.trackId, 'a');
    });

    test('a loop of repeat one during the pause starts a new listen', () async {
      recorder.start();
      playing([a]);
      listen(0, 25);
      paused = true;
      listen(25, 240);
      listen(0, 10);
      paused = false;
      listen(10, 30);
      await pumpEventQueue();
      expect(history.events, isEmpty, reason: '20 s heard since the loop');
    });

    test('a pause shorter than a seek still credits nothing', () async {
      recorder.start();
      playing([a]);
      listen(0, 28);
      paused = true;
      port.position.add(const Duration(milliseconds: 29600));
      paused = false;
      listen(30, 31);
      await pumpEventQueue();
      expect(history.events, isEmpty, reason: '29.4 s heard while recording');
    });

    test('the time heard before is written as the pause starts', () async {
      recorder.start();
      playing([a]);
      listen(0, 20);
      paused = true;
      listen(20, 21);
      await pumpEventQueue();

      expect(history.listening, {dayOf(at): const Duration(seconds: 20)});
    });

    test('a song started during the pause counts from its end', () async {
      recorder.start();
      playing([a]);
      paused = true;
      playing([b]);
      listen(0, 25);
      paused = false;
      listen(25, 50);
      await pumpEventQueue();
      expect(history.events, isEmpty, reason: '25 s heard since');

      listen(50, 56);
      await pumpEventQueue();
      expect(history.events.single.trackId, 'b');
    });
  });
}
