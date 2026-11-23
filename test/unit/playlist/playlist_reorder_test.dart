import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:troona/features/library/data/models/track_model.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/playlist/data/repositories/playlist_repository_impl.dart';

import '../../helpers/isar_host.dart';

TrackModel _row(String id, {bool excluded = false}) => TrackModel()
  ..deviceId = id
  ..path = '/m/$id.mp3'
  ..uri = 'content://$id'
  ..title = 'Title $id'
  ..artist = 'Artist'
  ..artistId = 1
  ..album = 'Album'
  ..albumId = 1
  ..genre = ''
  ..genreId = 0
  ..durationMs = 100000
  ..fileName = '$id.mp3'
  ..trackNumber = 0
  ..size = 1
  ..year = 0
  ..indexedAt = DateTime(2024)
  ..excluded = excluded;

void main() {
  late Directory dir;
  late Isar isar;
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
    dir = await Directory.systemTemp.createTemp('playlist_reorder_test');
    isar = Isar.open(
      schemas: IsarLibraryDataSource.schemas,
      directory: dir.path,
      inspector: false,
    );
    final source = IsarLibraryDataSource(isar);
    // b is left out of the library, gone was deleted from the phone.
    await source.insertTracks([
      _row('a'),
      _row('b', excluded: true),
      _row('c'),
      _row('d'),
    ]);
    repo = PlaylistRepositoryImpl(cache: source);
  });

  tearDown(() async {
    if (skip != null) return;
    isar.close(deleteFromDisk: true);
    await dir.delete(recursive: true);
  });

  Future<String> playlistOf(List<String> ids) async {
    final created = (await repo.createPlaylist(
      title: 'Mix',
    )).getOrElse(() => throw StateError('not created'));
    await repo.addTracksToPlaylist(created.id, ids);
    return created.id;
  }

  Future<List<String>> stored(String id) async => (await repo.getPlaylistById(
    id,
  )).getOrElse(() => throw StateError('not found')).trackIds;

  Future<List<String>> shown(String id) async => [
    for (final t in (await repo.getTracksByPlaylistId(
      id,
    )).getOrElse(() => throw StateError('not found')))
      t.id,
  ];

  test('moves the song the page shows at that place', () async {
    final id = await playlistOf(['a', 'b', 'gone', 'c', 'd']);
    expect(await shown(id), ['a', 'c', 'd']);

    // c, shown second, to the top.
    expect((await repo.reorderTracks(id, 1, 0)).isRight(), isTrue);

    expect(await shown(id), ['c', 'a', 'd']);
    // The hidden songs stay, in their place after a.
    expect(await stored(id), ['c', 'a', 'b', 'gone', 'd']);
  }, skip: skip);

  test('a place the page does not show changes nothing', () async {
    final id = await playlistOf(['a', 'b', 'c']);
    expect((await repo.reorderTracks(id, 2, 0)).isLeft(), isTrue);
    expect(await stored(id), ['a', 'b', 'c']);
  }, skip: skip);

  test('counts only the songs the page shows', () async {
    final id = await playlistOf(['a', 'b', 'gone', 'c']);

    final one = (await repo.getPlaylistById(
      id,
    )).getOrElse(() => throw StateError('not found'));
    expect(one.trackIds, hasLength(4), reason: 'the hidden ones are kept');
    expect(one.songCount, 2);
    final listed = (await repo.getPlaylists()).getOrElse(
      () => throw StateError('no list'),
    );
    expect(listed.firstWhere((p) => p.id == id).songCount, 2);
  }, skip: skip);
}
