import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';

import '../../helpers/fake_player.dart';

class _Library extends Fake implements LibraryRepository {
  Either<Failure, List<Track>> answer;
  _Library(this.answer);

  @override
  Future<Either<Failure, List<Track>>> getTracksByIds(List<String> ids) async =>
      answer;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final a = testTrack('a', durationMs: 200000);
  final b = testTrack('b', durationMs: 100000);

  late PlaybackSessionStore store;
  late FakeAudioPort port;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = PlaybackSessionStore(await SharedPreferences.getInstance());
    port = FakeAudioPort();
    await store.save(
      const PlaybackSessionSnapshot(
        currentTrackId: 'b',
        originalTrackIds: ['a', 'b'],
        playbackTrackIds: ['a', 'b'],
        currentIndex: 1,
        positionMs: 5000,
        wasPlaying: false,
        shuffleEnabled: false,
        repeatMode: RepeatMode.off,
        volume: 1,
        speed: 1,
      ),
    );
  });

  tearDown(() => port.close());

  Future<PlayerBloc> restoreWith(
    Either<Failure, List<Track>> answer, {
    bool play = false,
  }) async {
    final bloc = buildTestPlayerBloc(port, store, library: _Library(answer));
    addTearDown(bloc.close);
    bloc.add(RestorePlaybackSessionRequested(play: play));
    await pumpEventQueue();
    return bloc;
  }

  test('restores the saved track from the library', () async {
    final bloc = await restoreWith(right([a, b]));
    expect(bloc.state, isA<PlayerLoading>());
    expect((bloc.state as PlayerLoading).track, b);
    expect(port.restoredPlaying, isFalse);
  });

  test('the media controls restore it playing', () async {
    await restoreWith(right([a, b]), play: true);
    expect(port.restoredPlaying, isTrue);
  });

  test('a failed library read keeps the session for next time', () async {
    final bloc = await restoreWith(left(const DatabaseFailure()));
    expect(bloc.state, isA<PlayerIdle>());
    expect(store.load(), isNotNull);
  });

  test('songs gone from the library drop the session', () async {
    final bloc = await restoreWith(right(const []));
    expect(bloc.state, isA<PlayerIdle>());
    expect(store.load(), isNull);
  });
}
