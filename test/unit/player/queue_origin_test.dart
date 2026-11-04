import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/queue_origin.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';

import '../../helpers/fake_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final album = [
    for (final id in ['a', 'b', 'c']) testTrack(id, durationMs: 200000),
  ];
  final playlist = [
    for (final id in ['d', 'e']) testTrack(id, durationMs: 200000),
  ];
  final x = testTrack('x', durationMs: 200000);
  const ofAlbum = QueueOrigin(QueueOriginKind.album, id: '7', name: 'Damini');
  const ofPlaylist = QueueOrigin(
    QueueOriginKind.playlist,
    id: '3',
    name: 'Road trip',
  );

  late FakeAudioPort port;
  late PlaybackSessionStore store;
  late PlayerBloc bloc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = PlaybackSessionStore(await SharedPreferences.getInstance());
    port = FakeAudioPort();
    bloc = buildTestPlayerBloc(port, store);
    addTearDown(() async {
      await bloc.close();
      await port.close();
    });
  });

  Future<void> play(
    List<Track> tracks, {
    int index = 0,
    QueueOrigin? origin,
  }) async {
    bloc.add(
      PlayTrackRequested(
        tracks[index],
        contextQueue: tracks,
        contextIndex: index,
        origin: origin,
      ),
    );
    await pumpEventQueue();
    port.queue = Queue.fromTracks(tracks, startIndex: index);
    port.status.add(PlaybackStatus.playing);
    await pumpEventQueue();
  }

  test('a queue started from an album or a playlist names it', () async {
    expect(bloc.origin.value, isNull);
    await play(album, origin: ofAlbum);
    expect(bloc.origin.value, ofAlbum);
    await play(playlist, origin: ofPlaylist);
    expect(bloc.origin.value, ofPlaylist);
  });

  test('another song of the same album keeps it', () async {
    await play(album, origin: ofAlbum);
    await play(album, index: 2, origin: ofAlbum);
    expect(bloc.origin.value, ofAlbum);
  });

  test('a queue from a plain song list names nothing', () async {
    await play(album, origin: ofAlbum);
    await play([x]);
    expect(bloc.origin.value, isNull);
  });

  test('undoing a replaced queue brings its origin back', () async {
    await play(album, origin: ofAlbum);
    bloc.add(TrackQueuedNext(x));
    await pumpEventQueue();
    await play(playlist, origin: ofPlaylist);
    bloc.add(const QueueReplaceUndone());
    await pumpEventQueue();
    expect(bloc.origin.value, ofAlbum);
  });

  test('it is saved with the session, and dismissing forgets it', () async {
    await play(album, origin: ofAlbum);
    port.position.add(const Duration(seconds: 5));
    await pumpEventQueue();
    expect(store.load()?.origin, ofAlbum);

    bloc.add(const PlayerDismissed());
    await pumpEventQueue();
    expect(bloc.origin.value, isNull);
  });
}
