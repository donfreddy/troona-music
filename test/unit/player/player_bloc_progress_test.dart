import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';

import '../../helpers/fake_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAudioPort port;
  late PlaybackSessionStore store;
  late PlayerBloc bloc;
  late List<PlayerState> emitted;
  late StreamSubscription<PlayerState> sub;

  final track = testTrack('a', durationMs: 200000);
  final other = testTrack('b', durationMs: 100000);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    port = FakeAudioPort();
    store = PlaybackSessionStore(prefs);
    bloc = buildTestPlayerBloc(port, store);
    emitted = [];
    sub = bloc.stream.listen(emitted.add);
  });

  tearDown(() async {
    await sub.cancel();
    await bloc.close();
    await port.close();
  });

  Future<void> activate({
    int index = 0,
    RepeatMode repeatMode = RepeatMode.off,
    bool shuffled = false,
  }) async {
    final tracks = [track, other];
    port.queue = Queue(
      originalTracks: tracks,
      playbackTracks: shuffled ? tracks.reversed.toList() : tracks,
      currentIndex: index,
      shuffleEnabled: shuffled,
      repeatMode: repeatMode,
    );
    port.duration = Duration(milliseconds: tracks[index].durationMs);
    bloc.add(QueueSetRequested(port.queue!.playbackTracks, startIndex: index));
    await pumpEventQueue();
    port.status.add(PlaybackStatus.playing);
    await pumpEventQueue();
    expect(bloc.state, isA<PlayerActive>());
    emitted.clear();
  }

  group('PlaybackProgress', () {
    test('ratio is 0 when duration is unknown', () {
      const p = PlaybackProgress(
        position: Duration(seconds: 5),
        buffered: Duration.zero,
        duration: Duration.zero,
      );
      expect(p.ratio, 0);
    });

    test('ratio and remaining are clamped past the end', () {
      const p = PlaybackProgress(
        position: Duration(seconds: 12),
        buffered: Duration.zero,
        duration: Duration(seconds: 10),
      );
      expect(p.ratio, 1);
      expect(p.remaining, Duration.zero);
    });

    test('remaining is duration minus position', () {
      const p = PlaybackProgress(
        position: Duration(seconds: 4),
        buffered: Duration.zero,
        duration: Duration(seconds: 10),
      );
      expect(p.ratio, closeTo(0.4, 1e-9));
      expect(p.remaining, const Duration(seconds: 6));
    });
  });

  group('PlayerBloc queue edits', () {
    test('apply one after the other, insert index included', () async {
      await activate();
      // Only the call order matters: keep the fake from applying the edits.
      port.queue = null;
      bloc
        ..add(const QueueItemMoved(oldIndex: 3, newIndex: 2))
        ..add(const TrackRemovedFromQueue(index: 4))
        ..add(TrackAddedToQueue(other, index: 4));
      await pumpEventQueue();

      expect(port.queueEdits, [
        'start move 3>2',
        'end move 3>2',
        'start remove 4',
        'end remove 4',
        'start add b@4',
        'end add b@4',
      ]);
    });
  });

  group('PlayerBloc track changes', () {
    test('follow the playing entry when a track is queued twice', () async {
      // [a, b, a]: the second "a" starts after "b".
      port.queue = Queue.fromTracks([track, other, track], startIndex: 1);
      bloc.add(QueueSetRequested(port.queue!.playbackTracks, startIndex: 1));
      await pumpEventQueue();
      port.status.add(PlaybackStatus.playing);
      port.track.add(other);
      await pumpEventQueue();

      port.queue = port.queue!.copyWith(currentIndex: 2);
      port.track.add(track);
      await pumpEventQueue();

      final state = bloc.state as PlayerActive;
      expect(state.queue.currentIndex, 2);
      expect(state.currentTrack.id, 'a');
    });

    test('start on the requested copy of a track queued twice', () async {
      port.queue = Queue.fromTracks([track, other, track], startIndex: 2);
      bloc.add(QueueSetRequested(port.queue!.playbackTracks, startIndex: 2));
      await pumpEventQueue();
      port.track.add(track);
      port.status.add(PlaybackStatus.playing);
      await pumpEventQueue();

      expect((bloc.state as PlayerActive).queue.currentIndex, 2);
    });

    test('take the track from the port queue when the event lags', () async {
      await activate();
      // The port already moved on to "b" when the event for "a" arrives.
      port.queue = port.queue!.copyWith(currentIndex: 1);
      port.track.add(track);
      await pumpEventQueue();

      final state = bloc.state as PlayerActive;
      expect(state.currentTrack.id, 'b');
      expect(state.queue.currentIndex, 1);
    });
  });

  group('PlayerBloc progress clock', () {
    test('position ticks update progress without emitting states', () async {
      await activate();

      for (var ms = 0; ms < 1000; ms += 16) {
        port.position.add(Duration(milliseconds: ms));
      }
      await pumpEventQueue();

      expect(emitted, isEmpty);
      expect(bloc.progress.value.position, const Duration(milliseconds: 992));
    });

    test('buffered ticks update progress without emitting states', () async {
      await activate();

      port.buffered.add(const Duration(seconds: 30));
      await pumpEventQueue();

      expect(emitted, isEmpty);
      expect(bloc.progress.value.buffered, const Duration(seconds: 30));
    });

    test('progress mirrors the active track duration', () async {
      await activate();
      expect(bloc.progress.value.duration, const Duration(seconds: 200));
    });

    test(
      'seek updates progress optimistically and ignores stale ticks',
      () async {
        await activate();
        port.position.add(const Duration(seconds: 10));
        await pumpEventQueue();

        bloc.add(const SeekRequested(Duration(seconds: 90)));
        await pumpEventQueue();
        expect(bloc.progress.value.position, const Duration(seconds: 90));

        // A stale engine tick arriving during the seek window is ignored.
        port.position.add(const Duration(seconds: 10));
        await pumpEventQueue();
        expect(bloc.progress.value.position, const Duration(seconds: 90));
        expect(port.seeks, [const Duration(seconds: 90)]);
      },
    );

    test('a second seek while the first settles is still applied', () async {
      await activate();

      bloc.add(const SeekRequested(Duration(seconds: 30)));
      await pumpEventQueue();
      bloc.add(const SeekRequested(Duration(seconds: 60)));
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(port.seeks, [
        const Duration(seconds: 30),
        const Duration(seconds: 60),
      ]);
      expect(bloc.progress.value.position, const Duration(seconds: 60));
    });

    test('ticks are accepted again once the seek window closes', () async {
      await activate();
      bloc.add(const SeekRequested(Duration(seconds: 90)));
      await pumpEventQueue();

      await Future<void>.delayed(const Duration(milliseconds: 200));
      port.position.add(const Duration(seconds: 91));
      await pumpEventQueue();

      expect(bloc.progress.value.position, const Duration(seconds: 91));
    });

    test('identical structural updates are deduplicated', () async {
      await activate();

      port.status.add(PlaybackStatus.playing);
      await pumpEventQueue();

      expect(emitted, isEmpty);
    });

    test('a status change still emits', () async {
      await activate();

      port.status.add(PlaybackStatus.paused);
      await pumpEventQueue();

      expect(emitted, hasLength(1));
      expect((emitted.single as PlayerActive).status, PlaybackStatus.paused);
    });

    test('a volume change still emits', () async {
      await activate();

      bloc.add(const VolumeChangeRequested(0.4));
      await pumpEventQueue();

      expect(emitted, hasLength(1));
      expect((emitted.single as PlayerActive).volume, 0.4);
    });

    test('skip previous restarts the track after 3 seconds', () async {
      await activate();
      port.position.add(const Duration(seconds: 42));
      await pumpEventQueue();

      bloc.add(const SkipPreviousRequested());
      await pumpEventQueue();

      expect(port.seeks, [Duration.zero]);
      expect(port.skipPreviousCalls, 0);
      expect(bloc.progress.value.position, Duration.zero);
    });

    test('skip previous skips back from a middle track', () async {
      await activate(index: 1);
      port.position.add(const Duration(seconds: 1));
      await pumpEventQueue();

      bloc.add(const SkipPreviousRequested());
      await pumpEventQueue();

      expect(port.skipPreviousCalls, 1);
      expect(port.seeks, isEmpty);
    });

    test('skip previous wraps on the first track with repeat all', () async {
      await activate(repeatMode: RepeatMode.all);
      port.position.add(const Duration(seconds: 1));
      await pumpEventQueue();

      bloc.add(const SkipPreviousRequested());
      await pumpEventQueue();

      expect(port.skipPreviousCalls, 1);
      expect(port.seeks, isEmpty);
    });

    test('skip previous restarts the first track instead of no-op', () async {
      await activate();
      port.position.add(const Duration(seconds: 1));
      await pumpEventQueue();

      bloc.add(const SkipPreviousRequested());
      await pumpEventQueue();

      expect(port.seeks, [Duration.zero]);
      expect(port.skipPreviousCalls, 0);
    });

    test('track change resets the position', () async {
      await activate();
      port.position.add(const Duration(seconds: 42));
      await pumpEventQueue();

      port.queue = port.queue!.copyWith(currentIndex: 1);
      port.track.add(other);
      await pumpEventQueue();

      expect(bloc.progress.value.position, Duration.zero);
      expect(bloc.progress.value.duration, const Duration(seconds: 100));
    });

    test('a stale engine track does not override a requested track', () async {
      await activate();

      bloc.add(
        PlayTrackRequested(
          other,
          contextQueue: [track, other],
          contextIndex: 1,
        ),
      );
      await pumpEventQueue();
      expect((bloc.state as PlayerLoading).track.id, 'b');

      // While swapping sources the engine re-announces the previous index.
      port.track.add(track);
      await pumpEventQueue();
      expect((bloc.state as PlayerLoading).track.id, 'b');

      // The requested track is confirmed, then playback starts.
      port.queue = port.queue!.copyWith(currentIndex: 1);
      port.track.add(other);
      port.status.add(PlaybackStatus.playing);
      await pumpEventQueue();
      final active = bloc.state as PlayerActive;
      expect(active.currentTrack.id, 'b');
      expect(active.queue.currentIndex, 1);
    });

    test('a queue index request keeps the shuffled queue intact', () async {
      await activate(shuffled: true);
      final before = (bloc.state as PlayerActive).queue;
      port.setQueueCalls = 0;

      bloc.add(const QueueIndexRequested(1));
      await pumpEventQueue();
      expect(port.indexJumps, [1]);
      expect(port.setQueueCalls, 0);

      // The engine moves to index 1 of the same (shuffled) sources.
      port.queue = port.queue!.copyWith(currentIndex: 1);
      port.track.add(before.playbackTracks[1]);
      await pumpEventQueue();

      final after = (bloc.state as PlayerActive).queue;
      expect(after.currentIndex, 1);
      expect(after.shuffleEnabled, isTrue);
      expect(after.playbackTracks, before.playbackTracks);
      expect(after.originalTracks, before.originalTracks);
    });

    test(
      'a queue index request ignores the current or invalid index',
      () async {
        await activate();

        bloc.add(const QueueIndexRequested(0));
        await pumpEventQueue();
        bloc.add(const QueueIndexRequested(7));
        await pumpEventQueue();

        expect(port.indexJumps, isEmpty);
      },
    );

    test('engine track changes are followed again once active', () async {
      await activate();
      bloc.add(
        PlayTrackRequested(
          other,
          contextQueue: [track, other],
          contextIndex: 1,
        ),
      );
      await pumpEventQueue();
      port.queue = port.queue!.copyWith(currentIndex: 1);
      port.status.add(PlaybackStatus.playing);
      await pumpEventQueue();

      // Auto-advance or lock screen skip back to the first track.
      port.queue = port.queue!.copyWith(currentIndex: 0);
      port.track.add(track);
      await pumpEventQueue();
      expect((bloc.state as PlayerActive).currentTrack.id, 'a');
    });

    test(
      'loading a new track resets progress and ignores stale ticks',
      () async {
        await activate();
        port.position.add(const Duration(seconds: 42));
        await pumpEventQueue();

        bloc.add(QueueSetRequested([other]));
        await pumpEventQueue();
        expect(bloc.state, isA<PlayerLoading>());

        // A tick from the outgoing source must not leak into the new track.
        port.position.add(const Duration(seconds: 50));
        await pumpEventQueue();

        expect(bloc.progress.value.position, Duration.zero);
        expect(bloc.progress.value.duration, const Duration(seconds: 100));
      },
    );

    test('becoming active seeds the position from the engine', () async {
      port.currentPositionValue = const Duration(seconds: 33);
      await activate();

      expect(bloc.progress.value.position, const Duration(seconds: 33));
    });

    test('dismissing the player resets progress to zero', () async {
      await activate();
      port.position.add(const Duration(seconds: 42));
      await pumpEventQueue();

      bloc.add(const PlayerDismissed());
      await pumpEventQueue();

      expect(bloc.state, isA<PlayerIdle>());
      expect(bloc.progress.value, PlaybackProgress.zero);
    });

    test('end of queue rewinds to zero and pauses', () async {
      await activate();
      port.position.add(const Duration(seconds: 199));
      await pumpEventQueue();

      port.status.add(PlaybackStatus.stopped);
      await pumpEventQueue();

      expect((bloc.state as PlayerActive).status, PlaybackStatus.paused);
      expect(bloc.progress.value.position, Duration.zero);
      expect(port.seeks, [Duration.zero]);
    });

    test('ticks persist the position once per second', () async {
      await activate();

      port.position.add(const Duration(milliseconds: 42500));
      await pumpEventQueue();

      final snapshot = store.load();
      expect(snapshot?.currentTrackId, 'a');
      expect(snapshot?.positionMs, 42500);
    });

    test('ticks overtaking a track change are not persisted', () async {
      await activate();
      port.position.add(const Duration(seconds: 42));
      await pumpEventQueue();

      // The engine already switched, but _TrackChanged has not run yet.
      port.queue = port.queue!.copyWith(currentIndex: 1);
      port.position.add(const Duration(seconds: 77));
      await pumpEventQueue();

      final snapshot = store.load();
      expect(snapshot?.currentTrackId, 'a');
      expect(snapshot?.positionMs, 42000);
    });
  });
}
