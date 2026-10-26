import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/utils/play_shuffled.dart';

import '../../helpers/fake_player.dart';

void main() {
  final tracks = [
    for (var i = 0; i < 20; i++) testTrack('$i', durationMs: 60000),
  ];

  PlayerActive active({required bool shuffled}) => PlayerActive(
    currentTrack: tracks.first,
    status: PlaybackStatus.playing,
    duration: const Duration(minutes: 1),
    queue: Queue(
      originalTracks: tracks,
      playbackTracks: tracks,
      currentIndex: 0,
      shuffleEnabled: shuffled,
      repeatMode: RepeatMode.off,
    ),
    shuffleEnabled: shuffled,
    repeatMode: RepeatMode.off,
  );

  test('plays every track and turns shuffle on when it is off', () {
    for (final state in [const PlayerIdle(), active(shuffled: false)]) {
      final events = shuffledPlayEvents(state, tracks);

      expect(events, hasLength(2));
      final play = events.first as PlayTrackRequested;
      expect(play.contextQueue, unorderedEquals(tracks));
      expect(play.contextIndex, 0);
      expect(play.track, play.contextQueue!.first);
      expect(events.last, isA<ShuffleToggleRequested>());
    }
  });

  test('leaves shuffle on when it already is', () {
    final events = shuffledPlayEvents(active(shuffled: true), tracks);
    expect(events.single, isA<PlayTrackRequested>());
  });

  test('starts on a random track, not always the first', () {
    final starts = {
      for (var i = 0; i < 50; i++)
        (shuffledPlayEvents(const PlayerIdle(), tracks).first
                as PlayTrackRequested)
            .track
            .id,
    };
    expect(starts.length, greaterThan(1));
  });

  test('does nothing without tracks', () {
    expect(shuffledPlayEvents(const PlayerIdle(), const []), isEmpty);
  });

  test('does not reorder the caller list', () {
    final original = List.of(tracks);
    shuffledPlayEvents(const PlayerIdle(), tracks);
    expect(tracks, original);
  });
}
