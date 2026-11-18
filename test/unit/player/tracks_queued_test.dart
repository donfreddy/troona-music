import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/queue_origin.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';

import '../../helpers/fake_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final a = testTrack('a', durationMs: 200000);
  final b = testTrack('b', durationMs: 200000);
  final x = testTrack('x', durationMs: 200000);
  final y = testTrack('y', durationMs: 200000);
  final z = testTrack('z', durationMs: 200000);
  const album = QueueOrigin(QueueOriginKind.album, id: '7', name: 'Album');

  late FakeAudioPort port;
  late PlayerBloc bloc;
  late List<PlayerNotice> notices;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final store = PlaybackSessionStore(await SharedPreferences.getInstance());
    port = FakeAudioPort();
    bloc = buildTestPlayerBloc(port, store);
    notices = [];
    final sub = bloc.notices.listen(notices.add);
    addTearDown(() async {
      await sub.cancel();
      await bloc.close();
      await port.close();
    });
  });

  /// [a] then [b] playing, from [a].
  Future<void> playing() async {
    bloc.add(PlayTrackRequested(a, contextQueue: [a, b], contextIndex: 0));
    await pumpEventQueue();
    port.queue = Queue.fromTracks([a, b]);
    port.status.add(PlaybackStatus.playing);
    await pumpEventQueue();
    expect(bloc.state, isA<PlayerActive>());
  }

  List<String> queued() => [for (final t in port.queue!.playbackTracks) t.id];

  test('Play next puts them right after the current song, in order, '
      'with one notice counting them', () async {
    await playing();
    bloc.add(TracksQueued([x, y, z], next: true));
    await pumpEventQueue();
    expect(queued(), ['a', 'x', 'y', 'z', 'b']);
    expect(notices, [const TrackQueued(3)]);
  });

  test('Add to queue puts them at the end', () async {
    await playing();
    bloc.add(TracksQueued([x, y], next: false));
    await pumpEventQueue();
    expect(queued(), ['a', 'b', 'x', 'y']);
    expect(notices, [const TrackQueued(2)]);
  });

  test('they go in as one edit: refused, none is queued and nothing says '
      'so', () async {
    await playing();
    bloc.add(TracksQueued([x, y, z], next: true));
    await pumpEventQueue();
    expect(port.queueEdits, ['start add x,y,z@1', 'end add x,y,z@1']);

    port.failNextEdits = 1;
    bloc.add(TracksQueued([a, b], next: false));
    await pumpEventQueue();
    expect(queued(), ['a', 'x', 'y', 'z', 'b']);
    expect(notices, [const TrackQueued(3)], reason: 'none for the refused');
  });

  test(
    'with nothing loaded they play, from the first, as their album',
    () async {
      bloc.add(TracksQueued([x, y, z], next: true, origin: album));
      await pumpEventQueue();
      expect(port.setQueueCalls, 1);
      expect(port.lastSetQueue!.tracks, [x, y, z]);
      expect(port.lastSetQueue!.startIndex, 0);
      expect(bloc.origin.value, album);
      expect(notices, isEmpty, reason: 'nothing was queued');
    },
  );

  test('one song added with nothing loaded plays', () async {
    bloc.add(TrackAddedToQueue(x));
    await pumpEventQueue();
    expect((bloc.state as PlayerLoading).track, x);
    expect(notices, isEmpty);
  });

  test('one song at a time: a notice each', () async {
    await playing();
    bloc
      ..add(TrackQueuedNext(x))
      ..add(TrackAddedToQueue(y));
    await pumpEventQueue();
    expect(queued(), ['a', 'x', 'b', 'y']);
    expect(notices, [const TrackQueued(), const TrackQueued()]);
  });

  group('the cases where the queue is not the one to edit', () {
    final c = testTrack('c', durationMs: 200000);
    final d = testTrack('d', durationMs: 200000);

    test('after the mini player was swiped away, queueing plays: the '
        "engine's old queue is dead", () async {
      await playing();
      bloc.add(const PlayerDismissed());
      await pumpEventQueue();
      expect(bloc.state, isA<PlayerIdle>());
      expect(bloc.hasQueue, isFalse);
      final before = port.setQueueCalls;

      bloc.add(TracksQueued([x, y], next: false, origin: album));
      await pumpEventQueue();
      expect(port.setQueueCalls, before + 1);
      expect(port.lastSetQueue!.tracks, [x, y]);
      expect(notices, isEmpty);
    });

    test('one song after a dismissal plays too', () async {
      await playing();
      bloc.add(const PlayerDismissed());
      await pumpEventQueue();
      bloc.add(TrackQueuedNext(x));
      await pumpEventQueue();
      expect((bloc.state as PlayerLoading).track, x);
      expect(notices, isEmpty);
    });

    test(
      'queued while the first song loads: they wait for its queue',
      () async {
        bloc.add(PlayTrackRequested(a, contextQueue: [a, b], contextIndex: 0));
        await pumpEventQueue();
        expect(bloc.state, isA<PlayerLoading>());
        expect(port.currentQueue, isNull);

        bloc.add(TracksQueued([x], next: false));
        await pumpEventQueue();
        port.queue = Queue.fromTracks([a, b]);
        port.queueCtrl.add(port.queue!);
        await pumpEventQueue();
        expect(queued(), ['a', 'b', 'x']);
        expect(notices, [const TrackQueued(1)]);
      },
    );

    test('a first song that fails to load while songs wait for it: they '
        'play, without waiting any longer, and nothing says queued', () async {
      final load = port.loadGate = Completer<void>();
      bloc.add(PlayTrackRequested(a, contextQueue: [a, b], contextIndex: 0));
      await pumpEventQueue();
      expect(bloc.state, isA<PlayerLoading>());

      bloc.add(TracksQueued([x], next: false));
      await pumpEventQueue();
      expect(port.lastSetQueue!.tracks, [a, b], reason: 'still waiting');

      port.failLoads = true;
      load.complete();
      await pumpEventQueue();
      expect(bloc.state, isNot(isA<PlayerLoading>()));
      expect(bloc.hasQueue, isFalse);
      expect(port.lastSetQueue!.tracks, [x], reason: 'played at once');
      expect(notices, isEmpty);
    });

    test(
      'a new queue fading in: the songs go into it, not the one leaving',
      () async {
        await playing();
        bloc.add(PlayTrackRequested(c, contextQueue: [c, d], contextIndex: 0));
        await pumpEventQueue();
        expect(bloc.state, isA<PlayerLoading>());
        // The engine still holds [a, b] while it fades out.
        bloc.add(TracksQueued([x], next: true));
        await pumpEventQueue();
        expect(queued(), ['a', 'b'], reason: 'not into the queue leaving');

        port.queue = Queue.fromTracks([c, d]);
        port.queueCtrl.add(port.queue!);
        await pumpEventQueue();
        expect(queued(), ['c', 'x', 'd']);
      },
    );
  });
}
