import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:troona/features/library/data/models/playlist_model.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';

import '../../fixtures/v1_8_0/track_model.dart' as v18;
import '../../helpers/isar_host.dart';

/// A song as v1.8.0 stored it, before `TrackModel.excluded` existed: the
/// field comes before the cover and the date indexed in the schema.
v18.TrackModel _shipped(String id) => v18.TrackModel()
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
  ..indexedAt = DateTime(2025, 5, 6)
  ..artworkPath = '/cache/$id.jpg'
  ..artworkChecked = true;

void main() {
  final library = hostIsarLibrary();
  final skip = library == null
      ? 'No Isar core for ${Platform.operatingSystem}'
      : null;

  setUpAll(() async {
    if (library != null) await Isar.initialize(library);
  });

  test('a library stored by v1.8.0 opens whole', () async {
    final dir = await Directory.systemTemp.createTemp('schema_upgrade');
    addTearDown(() => dir.delete(recursive: true));
    final before = Isar.open(
      schemas: [v18.TrackModelSchema, PlaylistModelSchema],
      directory: dir.path,
      inspector: false,
    );
    before.write((isar) {
      for (final id in ['1', '2']) {
        final row = _shipped(id)..id = isar.trackModels.autoIncrement();
        isar.trackModels.put(row);
      }
    });
    before.close();

    final isar = Isar.open(
      schemas: IsarLibraryDataSource.schemas,
      directory: dir.path,
      inspector: false,
    );
    addTearDown(isar.close);
    final source = IsarLibraryDataSource(isar);

    final tracks = await source.getAllTracks();
    expect([for (final t in tracks) t.deviceId]..sort(), ['1', '2']);
    final one = tracks.firstWhere((t) => t.deviceId == '1');
    expect(one.excluded, isFalse);
    expect(one.artworkPath, '/cache/1.jpg');
    expect(one.artworkChecked, isTrue);
    expect(one.indexedAt, DateTime(2025, 5, 6));
    expect(await source.countTracks(), 2);
    expect(await source.getRecentTracks(), hasLength(2));
    expect(await source.getTracksWithoutArtwork(), isEmpty);
  }, skip: skip);
}
