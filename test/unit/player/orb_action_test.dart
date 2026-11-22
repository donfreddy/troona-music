import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/utils/orb_action.dart';

import '../../helpers/fake_player.dart';

void main() {
  test('nothing loaded: the saved session, else the library shuffled', () {
    expect(
      OrbAction.of(const PlayerIdle(), hasSession: true),
      OrbAction.resumeSession,
    );
    expect(
      OrbAction.of(const PlayerIdle(), hasSession: false),
      OrbAction.shuffleLibrary,
    );
  });

  test('a song loading opens Now Playing, session or not', () {
    for (final hasSession in [true, false]) {
      expect(
        OrbAction.of(
          PlayerLoading(testTrack('a', durationMs: 180000)),
          hasSession: hasSession,
        ),
        OrbAction.openNowPlaying,
      );
    }
  });

  test('an error keeps its song in the bar: the orb still opens it', () {
    expect(
      OrbAction.of(const PlayerError(message: 'boom'), hasSession: false),
      OrbAction.openNowPlaying,
    );
  });
}
