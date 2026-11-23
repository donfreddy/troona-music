import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:troona/features/library/data/models/track_model.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';

import '../../helpers/isar_host.dart';

TrackModel _row(String id, {bool excluded = false}) => TrackModel()
  ..deviceId = id
  ..path = '/m/$id.mp3'
  ..uri = 'content://$id'
  ..title = 'Title $id'
  ..artist = 'Artist'
  ..artistId = 1
  ..artistIds = [1]
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
  late IsarLibraryDataSource source;

  final library = hostIsarLibrary();
  final skip = library == null
      ? 'No Isar core for ${Platform.operatingSystem}'
      : null;

  setUpAll(() async {
    if (library != null) await Isar.initialize(library);
  });

  setUp(() async {
    if (skip != null) return;
    dir = await Directory.systemTemp.createTemp('excluded_flag_test');
    isar = Isar.open(
      schemas: IsarLibraryDataSource.schemas,
      directory: dir.path,
      inspector: false,
    );
    source = IsarLibraryDataSource(isar);
  });

  tearDown(() async {
    if (skip != null) return;
    isar.close(deleteFromDisk: true);
    await dir.delete(recursive: true);
  });

  test('a row stored before the flag existed is in the library', () async {
    await source.insertTracks([_row('old')]);
    // A row written by an older schema holds no value for the flag: null,
    // which an equality with false never matches.
    final json = isar.read((i) => i.trackModels.where().exportJson());
    isar.write((i) {
      i.trackModels.clear();
      i.trackModels.importJson([
        for (final m in json) {...m, 'excluded': null},
      ]);
    });
    expect(
      isar.read((i) => i.trackModels.where().excludedEqualTo(false).count()),
      0,
      reason: 'the null the older schema leaves',
    );

    expect(await source.getAllTracks(), hasLength(1));
    expect(await source.countTracks(), 1);
    expect(await source.searchTracks('Title'), hasLength(1));
    expect(await source.getTracksByArtistId(1), hasLength(1));
    expect(await source.getAlbumTracksByArtistId(1), hasLength(1));
    expect(await source.getTracksByAlbumId(1), hasLength(1));
    expect(await source.getRecentTracks(), hasLength(1));
    expect(await source.getTracksWithoutArtwork(), hasLength(1));
    expect(await source.getTracksByIds(['old']), hasLength(1));
  }, skip: skip);

  test('a song left out is kept but no library read shows it', () async {
    await source.insertTracks([_row('in'), _row('out', excluded: true)]);

    expect([for (final t in await source.getAllTracks()) t.deviceId], ['in']);
    expect(await source.countTracks(), 1);
    expect(await source.searchTracks('Title'), hasLength(1));
    expect(await source.getTracksByArtistId(1), hasLength(1));
    expect(await source.getAlbumTracksByArtistId(1), hasLength(1));
    expect(await source.getTracksByAlbumId(1), hasLength(1));
    expect(await source.getRecentTracks(), hasLength(1));
    expect(await source.getTracksWithoutArtwork(), hasLength(1));
    expect(await source.getTracksByIds(['in', 'out']), hasLength(1));
    // Backups and restores still see it.
    expect(await source.getStoredTracks(), hasLength(2));
  }, skip: skip);

}
