import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/playlist/data/repositories/playlist_repository_impl.dart';
import 'package:troona/features/playlist/presentation/widgets/add_to_playlist_sheet.dart';

import '../../helpers/fake_player.dart';
import '../../helpers/isar_host.dart';

void main() {
  final a = testTrack('a', durationMs: 1000);
  final b = testTrack('b', durationMs: 1000);
  final c = testTrack('c', durationMs: 1000);

  test('the songs a playlist lacks, in order, each once', () {
    const holdsB = Playlist(id: 'p', name: 'P', trackIds: ['b']);
    expect(missingTrackIds(holdsB, [c, b, a, c]), ['c', 'a']);
    expect(missingTrackIds(holdsB, [b]), isEmpty);
  });

  group('songs added to a playlist at once', () {
    late Directory dir;
    late Isar isar;
    late IsarLibraryDataSource source;
    late PlaylistRepositoryImpl repo;

    final library = hostIsarLibrary();
    final skip = library == null
        ? 'No Isar core for ${Platform.operatingSystem}'
        : null;

    setUpAll(() async {
      if (library != null) await Isar.initialize(library);
    });

    setUp(() async {
      if (skip != null) return;
      dir = await Directory.systemTemp.createTemp('playlist_bulk_add_test');
      isar = Isar.open(
        schemas: IsarLibraryDataSource.schemas,
        directory: dir.path,
        inspector: false,
      );
      source = IsarLibraryDataSource(isar);
      repo = PlaylistRepositoryImpl(cache: source);
    });

    tearDown(() async {
      if (skip != null) return;
      isar.close(deleteFromDisk: true);
      await dir.delete(recursive: true);
    });

    Future<List<String>> idsOf(String playlistId) async =>
        (await source.getPlaylistById(playlistId))!.trackIds;

    test('go in one write, in order, after the ones it holds', () async {
      final p = await source.createPlaylist(title: 'P');
      await source.addTrackToPlaylist(p.playlistId, 'b');
      var writes = 0;
      final sub = source.watchPlaylists().listen((_) => writes++);
      addTearDown(sub.cancel);

      final added = await repo.addTracksToPlaylist(p.playlistId, [
        'c',
        'b',
        'a',
        'c',
      ]);
      await pumpEventQueue();

      expect(added.getOrElse(() => []), ['c', 'a']);
      expect(await idsOf(p.playlistId), ['b', 'c', 'a']);
      expect(writes, 1);
    }, skip: skip);

    test('nothing missing writes nothing', () async {
      final p = await source.createPlaylist(title: 'P');
      await source.addTrackToPlaylist(p.playlistId, 'a');
      var writes = 0;
      final sub = source.watchPlaylists().listen((_) => writes++);
      addTearDown(sub.cancel);

      final added = await repo.addTracksToPlaylist(p.playlistId, ['a']);
      await pumpEventQueue();
      expect(added.getOrElse(() => ['x']), isEmpty);
      expect(writes, 0);
    }, skip: skip);

    test('a playlist gone takes none', () async {
      final added = await repo.addTracksToPlaylist('gone', ['a']);
      expect(added.getOrElse(() => ['x']), isEmpty);
    }, skip: skip);

    test('Undo takes them back in one write, keeping the others', () async {
      final p = await source.createPlaylist(title: 'P');
      await source.addTrackToPlaylist(p.playlistId, 'b');
      await repo.addTracksToPlaylist(p.playlistId, ['a', 'c']);

      await repo.removeTracksFromPlaylist(p.playlistId, ['a', 'c']);
      expect(await idsOf(p.playlistId), ['b']);
    }, skip: skip);
  });
}
