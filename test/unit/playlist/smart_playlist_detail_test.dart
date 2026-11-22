import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/smart_rules.dart';
import 'package:troona/features/playlist/presentation/bloc/playlist_detail/playlist_detail_bloc.dart';

import '../../helpers/fake_player.dart';
import '../../helpers/fake_smart.dart';

void main() {
  late FakeSmartLibrary library;
  late FakeSmartHistory history;
  late MemoryPlaylists playlists;

  setUp(() {
    library = FakeSmartLibrary([
      for (final id in ['c', 'a', 'd', 'b', 'e', 'f', 'g', 'h'])
        testTrack(id, durationMs: 60000),
    ]);
    history = FakeSmartHistory();
    playlists = MemoryPlaylists()
      ..stored['s'] = const Playlist(
        id: 's',
        name: 'Smart',
        rules: SmartRules(rules: [Liked(false)]),
      )
      ..stored['r'] = const Playlist(
        id: 'r',
        name: 'Shuffled',
        rules: SmartRules(sort: SmartSort.random),
      );
  });

  PlaylistDetailBloc build({int seed = 7}) {
    final bloc = PlaylistDetailBloc(
      repo: playlists,
      smart: fakeSmartSource(
        library: library,
        history: history,
        playlists: playlists,
      ),
      playsRecorded: history.changes,
      seed: seed,
    );
    addTearDown(bloc.close);
    return bloc;
  }

  Future<List<String>> load(PlaylistDetailBloc bloc, String id) async {
    bloc.add(PlaylistDetailRequested(id));
    final state = await bloc.stream.firstWhere(
      (s) => s is PlaylistDetailLoaded,
    );
    return [for (final t in (state as PlaylistDetailLoaded).data.tracks) t.id];
  }

  test('a smart playlist shows what its rules keep, sorted', () async {
    final ids = await load(build(), 's');
    // Sorted by title, never read from stored songs (the fake throws).
    expect(ids, ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']);
  });

  for (final (what, fail) in [
    ('library', () => library.fails = true),
    ('history', () => history.fails = true),
    ('liked songs', () => playlists.failLikes = true),
  ]) {
    test('$what that cannot be read: an error, never "no song" or every '
        'song', () async {
      fail();
      final bloc = build()..add(const PlaylistDetailRequested('s'));
      expect(
        await bloc.stream.firstWhere(
          (s) => s is PlaylistDetailLoaded || s is PlaylistDetailError,
        ),
        isA<PlaylistDetailError>(),
      );
    });
  }

  test('a reload that cannot read keeps the songs shown', () async {
    final bloc = build();
    final shown = await load(bloc, 's');
    library.fails = true;
    bloc.add(const PlaylistDetailRequested('s'));
    await Future<void>.delayed(Duration.zero);
    final state = bloc.state as PlaylistDetailLoaded;
    expect([for (final t in state.data.tracks) t.id], shown);
  });

  test('a random order holds across reloads while the page is open', () async {
    final bloc = build(seed: 3);
    final first = await load(bloc, 'r');
    final again = await load(bloc, 'r');
    expect(again, first);
    // Another seed, another page: a different order (8! orders).
    expect(await load(build(seed: 11), 'r'), isNot(first));
  });

  test('a play recorded reads a smart playlist again', () async {
    final bloc = build();
    await load(bloc, 's');
    final reads = library.reads;
    history.plays.add(null);
    await bloc.stream.firstWhere((s) => s is PlaylistDetailLoaded);
    expect(library.reads, reads + 1);
  });

  test('a play recorded leaves a playlist of songs alone', () async {
    playlists.stored['p'] = const Playlist(id: 'p', name: 'Songs');
    final bloc = build();
    await load(bloc, 'p');
    final reads = library.reads;
    history.plays.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(library.reads, reads);
  });

  group('save as a playlist', () {
    test('copies the songs in the order shown', () async {
      final bloc = build(seed: 5);
      final shown = await load(bloc, 'r');
      Playlist? saved;
      bloc.add(PlaylistSaveAsRequested('Copy', onSaved: (p) => saved = p));
      await Future<void>.delayed(Duration.zero);

      expect(saved!.name, 'Copy');
      final stored = playlists.stored[saved!.id]!;
      expect(stored.isSmart, isFalse);
      expect(stored.trackIds, shown);
    });

    test('a write that fails leaves no empty playlist behind', () async {
      final bloc = build();
      await load(bloc, 's');
      playlists.failAdds = true;
      var called = false;
      var failed = false;
      bloc.add(
        PlaylistSaveAsRequested(
          'Copy',
          onSaved: (_) => called = true,
          onFailed: () => failed = true,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(called, isFalse);
      expect(failed, isTrue);
      expect(playlists.deleted, [playlists.created.single.id]);
      expect(playlists.stored.keys, unorderedEquals(['s', 'r']));
    });

    test('a blank name writes nothing', () async {
      final bloc = build();
      await load(bloc, 's');
      bloc.add(const PlaylistSaveAsRequested('  '));
      await Future<void>.delayed(Duration.zero);
      expect(playlists.created, isEmpty);
    });
  });
}
