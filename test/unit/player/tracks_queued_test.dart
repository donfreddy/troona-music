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

  test(
    'a song the player refuses is left out of the order and the count',
    () async {
      await playing();
      port.failNextEdits = 1;
      bloc.add(TracksQueued([x, y, z], next: true));
      await pumpEventQueue();
      expect(queued(), ['a', 'y', 'z', 'b']);
      expect(notices, [const TrackQueued(2)]);

      port.failEdits = true;
      bloc.add(TracksQueued([x], next: true));
      await pumpEventQueue();
      expect(notices, [
        const TrackQueued(2),
      ], reason: 'nothing queued, no word');
    },
  );

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
}
