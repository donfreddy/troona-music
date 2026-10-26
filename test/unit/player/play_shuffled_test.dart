import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
