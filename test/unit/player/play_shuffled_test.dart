import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/utils/play_shuffled.dart';

import '../../helpers/fake_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tracks = [
    for (var i = 0; i < 20; i++) testTrack('$i', durationMs: 60000),
  ];

  test('the bloc asks for the source order with shuffle on', () async {
    SharedPreferences.setMockInitialValues({});
    final port = FakeAudioPort();
    final bloc = buildTestPlayerBloc(
      port,
      PlaybackSessionStore(await SharedPreferences.getInstance()),
    );
    addTearDown(() async {
      await bloc.close();
      await port.close();
    });

    playShuffled(bloc, tracks);
    await pumpEventQueue();

    final call = port.lastSetQueue!;
    expect(call.shuffle, isTrue);
    expect(call.tracks, tracks, reason: 'source order kept for un-shuffle');
    expect(bloc.state, isA<PlayerLoading>());
    expect((bloc.state as PlayerLoading).track, tracks[call.startIndex]);
  });

  group('a new list', () {
    var keep = true;
    late FakeAudioPort port;
    late PlayerBloc bloc;

    setUp(() async {
      keep = true;
      SharedPreferences.setMockInitialValues({});
      port = FakeAudioPort();
      bloc = buildTestPlayerBloc(
        port,
        PlaybackSessionStore(await SharedPreferences.getInstance()),
        keepShuffle: () => keep,
      );
    });

    tearDown(() async {
      await bloc.close();
      await port.close();
    });

    Future<bool?> shuffleOf(PlayerEvent event) async {
      bloc.add(event);
      await pumpEventQueue();
      return port.lastSetQueue!.shuffle;
    }

    final tap = PlayTrackRequested(
      tracks[2],
      contextQueue: tracks,
      contextIndex: 2,
    );

    test('keeps the shuffle mode when Settings keep it', () async {
      expect(await shuffleOf(tap), isNull);
    });

    test('plays in order when Settings do not keep it', () async {
      keep = false;
      expect(await shuffleOf(tap), isFalse);
      expect(await shuffleOf(QueueSetRequested(tracks)), isFalse);
    });

    /// The source shuffled and playing, as the Shuffle button leaves it.
    Future<void> shuffledSource() async {
      playShuffled(bloc, tracks);
      await pumpEventQueue();
      final call = port.lastSetQueue!;
      port.queue = Queue.fromTracks(
        call.tracks,
        startIndex: call.startIndex,
        shuffleEnabled: true,
      );
      port.status.add(PlaybackStatus.playing);
      await pumpEventQueue();
      expect(bloc.state, isA<PlayerActive>());
    }

    test('Play on the source shuffling plays it in order when Settings do '
        'not keep shuffle', () async {
      keep = false;
      await shuffledSource();
      final loads = port.setQueueCalls;

      expect(
        await shuffleOf(
          PlayTrackRequested(tracks[0], contextQueue: tracks, contextIndex: 0),
        ),
        isFalse,
      );
      expect(port.setQueueCalls, loads + 1, reason: 'rebuilt, not jumped in');
      expect(port.indexJumps, isEmpty);
    });

    test('kept, a song of the source shuffling is a jump within it', () async {
      await shuffledSource();
      final loads = port.setQueueCalls;

      bloc.add(
        PlayTrackRequested(tracks[5], contextQueue: tracks, contextIndex: 5),
      );
      await pumpEventQueue();

      expect(port.setQueueCalls, loads);
      expect(port.indexJumps, isNotEmpty);
    });

    test('the Shuffle button shuffles either way', () async {
      keep = false;
      playShuffled(bloc, tracks);
      await pumpEventQueue();
      expect(port.lastSetQueue!.shuffle, isTrue);
    });
  });

  test('starts on a random track, not always the first', () {
    final starts = {
      for (var seed = 0; seed < 20; seed++)
        shuffledPlayEvent(tracks, random: Random(seed))!.contextIndex,
    };
    expect(starts.length, greaterThan(1));
  });

  test('the event plays the track it starts on', () {
    final event = shuffledPlayEvent(tracks, random: Random(3))!;
    expect(event.track, tracks[event.contextIndex!]);
    expect(event.shuffle, isTrue);
  });

  test('does nothing without tracks', () {
    expect(shuffledPlayEvent(const []), isNull);
  });
}
