import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/opened_audio.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/utils/play_opened_file.dart';

import '../../helpers/fake_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlayerBloc player;
  late FakeAudioPort port;
  late List<String> calls;
  final song = testTrack('42', durationMs: 180000);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final store = PlaybackSessionStore(await SharedPreferences.getInstance());
    port = FakeAudioPort();
    player = buildTestPlayerBloc(port, store);
    calls = [];
    addTearDown(() async {
      await player.close();
      await port.close();
    });
  });

  void open(OpenedAudio opened, {bool onTop = false}) => playOpenedFile(
    opened,
    player: player,
    nowPlayingOnTop: onTop,
    skipRestore: () => calls.add('skip restore'),
    showNowPlaying: () => calls.add('now playing'),
    sayNotInLibrary: () => calls.add('not in library'),
  );

  test('a song of the library: the restore steps aside, the song plays '
      'alone, Now Playing shows', () async {
    open(OpenedLibraryTrack(song));
    await pumpEventQueue();
    expect(calls, ['skip restore', 'now playing']);
    expect((player.state as PlayerLoading).track, song);
  });

  test('Now Playing already on top: not pushed again', () async {
    open(OpenedLibraryTrack(song), onTop: true);
    await pumpEventQueue();
    expect(calls, ['skip restore']);
  });

  test(
    'not in the library: said so, nothing played, the restore kept',
    () async {
      open(const OpenedNotInLibrary());
      await pumpEventQueue();
      expect(calls, ['not in library']);
      expect(player.state, isA<PlayerIdle>());
    },
  );
}
