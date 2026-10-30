import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_by_ids_use_case.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';
import 'package:troona/services/audio/playback_resumer.dart';

import '../../helpers/fake_player.dart';

class _Library extends Fake implements LibraryRepository {
  _Library(this.tracks);

  final List<Track> tracks;

  @override
  Future<Either<Failure, List<Track>>> getTracksByIds(List<String> ids) async =>
      right(tracks.where((t) => ids.contains(t.id)).toList());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final a = testTrack('a', durationMs: 200000);
  final b = testTrack('b', durationMs: 100000);

  late PlaybackSessionStore store;
  late FakeAudioPort port;
  late PlaybackResumer resumer;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = PlaybackSessionStore(await SharedPreferences.getInstance());
    port = FakeAudioPort();
    final library = _Library([a, b]);
    final player = buildTestPlayerBloc(port, store, library: library);
    addTearDown(player.close);
    resumer = PlaybackResumer(
      store: store,
      getTracksByIds: GetTracksByIdsUseCase(library),
      player: player,
    );
  });

  tearDown(() => port.close());

  Future<void> saveSessionOn(String trackId) => store.save(
    PlaybackSessionSnapshot(
      currentTrackId: trackId,
      originalTrackIds: const ['a', 'b'],
      playbackTrackIds: const ['a', 'b'],
      currentIndex: 1,
      positionMs: 5000,
      wasPlaying: false,
      shuffleEnabled: false,
      repeatMode: RepeatMode.off,
      volume: 1,
      speed: 1,
    ),
  );

  test('no saved session has no last track', () async {
    expect(await resumer.lastTrack(), isNull);
  });

  test('the last track is the one the session stopped on', () async {
    await saveSessionOn('b');
    expect(await resumer.lastTrack(), b);
  });

  test('resuming restores the session playing', () async {
    await saveSessionOn('b');

    await resumer.resume();
    await pumpEventQueue();

    expect(port.restoredPlaying, isTrue);
  });
}
