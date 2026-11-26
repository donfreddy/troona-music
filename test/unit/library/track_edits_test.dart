import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:troona/features/library/data/models/track_edit_model.dart';
import 'package:troona/features/library/data/models/track_model.dart';
import 'package:troona/features/library/data/repositories/track_edit_repository_impl.dart';
import 'package:troona/features/library/data/services/track_edit_match.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/data/sources/isar_track_edit_data_source.dart';
import 'package:troona/features/library/domain/entities/track_edit.dart';
import 'package:troona/features/library/domain/services/track_tags.dart';

import '../../helpers/isar_host.dart';

TrackModel _row(
  String id, {
  String? title,
  String artist = 'Chily',
  String album = 'Album',
  int albumId = 1,
  int year = 2020,
  String? fileName,
  int size = 1,
}) => TrackModel()
  ..deviceId = id
  ..path = '/m/$id.mp3'
  ..uri = 'content://$id'
  ..title = title ?? 'Title $id'
  ..artist = artist
  ..artistId = TrackTags.artistIdFor(artist)
  ..album = album
  ..albumId = albumId
  ..genre = ''
  ..genreId = 0
  ..durationMs = 100000
  ..fileName = fileName ?? '$id.mp3'
  ..trackNumber = 0
  ..size = size
  ..year = year
  ..indexedAt = DateTime(2024);

TrackEditModel _edit(
  String id, {
  String? fileName,
  int size = 1,
  String? title,
  String? artist,
  String? album,
  int? year,
}) => TrackEditModel()
  ..deviceId = id
  ..fileName = fileName ?? '$id.mp3'
  ..size = size
  ..title = title
  ..artist = artist
  ..album = album
  ..year = year
  ..editedAt = DateTime(2026);

void main() {
  group('matching', () {
    test('an edit lands on its song by id, the file values kept aside', () {
      final song = _row('1', title: 'Tilte');
      final rekeyed = TrackEditMatch.apply(
        [song],
        [_edit('1', title: 'Title', year: 2021)],
      );
      expect(rekeyed, isEmpty);
      expect(song.title, 'Title');
      expect(song.fileTitle, 'Tilte');
      expect(song.year, 2021);
      expect(song.fileYear, 2020);
      expect(song.fileArtist, isNull, reason: 'not corrected');
      expect(
        song.fileTags(),
        const TrackFileTags(
          title: 'Tilte',
          artist: 'Chily',
          album: 'Album',
          year: 2020,
        ),
      );
    });

    test('a moved file keeps its edit, under its new id', () {
      final moved = _row('9', fileName: 'song.mp3', size: 42);
      final edit = _edit('1', fileName: 'song.mp3', size: 42, title: 'Mine');
      final rekeyed = TrackEditMatch.apply([moved], [edit]);
      expect(moved.title, 'Mine');
      expect(rekeyed.single.deviceId, '9');
    });

    test('two files of that name and size: neither takes the edit', () {
      final a = _row('8', fileName: 'song.mp3', size: 42);
      final b = _row('9', fileName: 'song.mp3', size: 42);
      final rekeyed = TrackEditMatch.apply(
        [a, b],
        [_edit('1', fileName: 'song.mp3', size: 42, title: 'Mine')],
      );
      expect(rekeyed, isEmpty);
      expect([a.title, b.title], ['Title 8', 'Title 9']);
    });

    test('a song that kept its id is never taken by a moved file\'s edit', () {
      final kept = _row('1', fileName: 'song.mp3', size: 42);
      final rekeyed = TrackEditMatch.apply(
        [kept],
        [
          _edit('7', fileName: 'song.mp3', size: 42, title: 'Moved'),
          _edit('1', fileName: 'song.mp3', size: 42, title: 'Kept'),
        ],
      );
      expect(kept.title, 'Kept');
      expect(rekeyed, isEmpty);
    });

    test('an edit whose song is gone is left as it is', () {
      final edit = _edit('1', title: 'Mine');
      expect(TrackEditMatch.apply([_row('2')], [edit]), isEmpty);
      expect(edit.deviceId, '1');
    });
  });

  group('grouping', () {
    test('a corrected artist joins the artist and the album of the others', () {
      final songs = [
        _row('1', artist: 'Chily', album: 'Doux', albumId: 10),
        _row('2', artist: 'chily', album: 'Doux', albumId: 11),
      ];
      TrackEditMatch.apply(songs, [_edit('2', artist: 'Chily')]);
      TrackModel.link(songs);
      expect(songs[1].artistIds, songs[0].artistIds);
      expect(songs[1].albumId, songs[0].albumId, reason: 'one album again');
      expect(songs[1].fileArtist, 'chily');
    });

    test('a corrected album name joins the album it was split from', () {
      final songs = [
        _row('1', album: 'Doux', albumId: 10),
        _row('2', album: 'Doux (1)', albumId: 11),
      ];
      TrackEditMatch.apply(songs, [_edit('2', album: 'Doux')]);
      TrackModel.link(songs);
      expect(songs[1].albumId, songs[0].albumId);
    });

    test(
      'a stored row takes a scan\'s correction, and loses it when it goes',
      () {
        final stored = _row('1');
        final scanned = _row('1');
        TrackEditMatch.apply([scanned], [_edit('1', title: 'Mine')]);
        expect(stored.refreshFrom(scanned), isTrue);
        expect((stored.title, stored.fileTitle), ('Mine', 'Title 1'));

        expect(stored.refreshFrom(_row('1')), isTrue);
        expect((stored.title, stored.fileTitle), ('Title 1', null));
      },
    );

    test('a picked cover shows over the file\'s, which is kept', () {
      final song = _row('1')..artworkPath = '/cache/1.jpg';
      TrackEditMatch.apply([song], [_edit('1')..coverPath = '/covers/a.png']);
      expect(song.toEntity().artworkPath, '/covers/a.png');
      expect(song.artworkPath, '/cache/1.jpg');
      expect(song.fileTags().coverPath, '/cache/1.jpg');
    });
  });

  group('repository', () {
    final library = hostIsarLibrary();
    final skip = library == null
        ? 'No Isar core for ${Platform.operatingSystem}'
        : null;

    late Directory dir;
    late Isar isar;
    late IsarTrackEditDataSource source;
    late TrackEditRepositoryImpl repo;
    late Directory covers;

    setUpAll(() async {
      if (library != null) await Isar.initialize(library);
    });

    setUp(() async {
      if (skip != null) return;
      dir = await Directory.systemTemp.createTemp('track_edits_test');
      covers = Directory('${dir.path}/covers');
      isar = Isar.open(
        schemas: [
          ...IsarLibraryDataSource.schemas,
          ...IsarTrackEditDataSource.schemas,
        ],
        directory: dir.path,
        inspector: false,
      );
      source = IsarTrackEditDataSource(isar);
      repo = TrackEditRepositoryImpl(source, coversDir: () async => covers);
      isar.write(
        (isar) =>
            isar.trackModels.putAll([_row('1')..id = 1, _row('2')..id = 2]),
      );
    });

    tearDown(() async {
      if (skip != null) return;
      isar.close(deleteFromDisk: true);
      await dir.delete(recursive: true);
    });

    TrackEdit editOf(String id) =>
        source.ofDevice(id)?.toEntity() ?? TrackEdit.none;

    test('saves a correction and tells the library to scan', () async {
      var changes = 0;
      final sub = repo.changes.listen((_) => changes++);
      addTearDown(sub.cancel);
      final song = _row('1').toEntity();

      final saved = await repo.save(
        [song],
        const TrackEdit(title: 'Mine', artist: 'Chily', year: 2021),
        fields: {
          TrackEditField.title,
          TrackEditField.artist,
          TrackEditField.year,
        },
      );
      await pumpEventQueue();

      expect(saved.isRight(), isTrue);
      expect(
        editOf('1'),
        const TrackEdit(title: 'Mine', year: 2021),
        reason: 'the artist is what the file says: no correction',
      );
      expect(source.ofDevice('1')!.fileName, '1.mp3');
      expect(changes, 1);

      final draft = (await repo.draftOf(song)).getOrElse(() => throw 'none');
      expect(draft.edit, editOf('1'));
      expect(draft.file.title, 'Title 1');
    }, skip: skip);

    test(
      'an album\'s fields land on each song, keeping each one\'s own',
      () async {
        final songs = [_row('1').toEntity(), _row('2').toEntity()];
        await repo.save(
          [songs[0]],
          const TrackEdit(title: 'One'),
          fields: {TrackEditField.title},
        );

        await repo.save(
          songs,
          const TrackEdit(album: 'Doux', year: 2019),
          fields: {TrackEditField.album, TrackEditField.year},
        );

        expect(
          editOf('1'),
          const TrackEdit(title: 'One', album: 'Doux', year: 2019),
        );
        expect(editOf('2'), const TrackEdit(album: 'Doux', year: 2019));
      },
      skip: skip,
    );

    test(
      'a field cleared shows the file again; nothing left, no row',
      () async {
        final song = _row('1').toEntity();
        await repo.save(
          [song],
          const TrackEdit(title: 'Mine', album: 'Other'),
          fields: {TrackEditField.title, TrackEditField.album},
        );

        await repo.save([song], TrackEdit.none, fields: {TrackEditField.title});
        expect(editOf('1'), const TrackEdit(album: 'Other'));

        await repo.save([song], TrackEdit.none, fields: {TrackEditField.album});
        expect(source.all(), isEmpty);
      },
      skip: skip,
    );

    test('a picked cover is copied in for every song, and deleted once no '
        'correction names it', () async {
      final picked = File('${dir.path}/picked.png')..writeAsBytesSync([1, 2]);
      final songs = [_row('1').toEntity(), _row('2').toEntity()];

      await repo.save(
        songs,
        TrackEdit.none,
        fields: {TrackEditField.cover},
        pickedCover: picked.path,
      );
      final copy = editOf('1').coverPath!;
      expect(editOf('2').coverPath, copy);
      expect(copy, startsWith(covers.path));
      expect(copy, endsWith('.png'));
      expect(File(copy).readAsBytesSync(), [1, 2]);

      await repo.save(songs, TrackEdit.none, fields: {TrackEditField.cover});
      expect(File(copy).existsSync(), isFalse);
      expect(picked.existsSync(), isTrue, reason: 'the user\'s own file');
    }, skip: skip);

    test('a picture too large is refused, and nothing is saved', () async {
      final huge = File('${dir.path}/huge.jpg')
        ..writeAsBytesSync(
          List.filled(TrackEditRepositoryImpl.maxCoverBytes + 1, 0),
        );
      final saved = await repo.save(
        [_row('1').toEntity()],
        const TrackEdit(title: 'Mine'),
        fields: {TrackEditField.title, TrackEditField.cover},
        pickedCover: huge.path,
      );
      expect(saved.isLeft(), isTrue);
      expect(source.all(), isEmpty);
    }, skip: skip);
  });
}
