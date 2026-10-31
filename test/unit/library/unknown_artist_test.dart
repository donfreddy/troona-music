import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:troona/features/library/data/models/track_model.dart';
import 'package:troona/features/library/data/repositories/album_detail_repository_impl.dart';
import 'package:troona/features/library/data/repositories/artist_detail_repository_impl.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/services/library_grouping.dart';
import 'package:troona/features/library/domain/services/track_tags.dart';
import 'package:troona/features/search/data/repositories/search_repository_impl.dart';

import '../../helpers/isar_host.dart';

/// What Android reports for a file without an artist tag.
const _androidUnknownId = 7;

TrackModel _track(
  String deviceId, {
  required String title,
  String artist = '<unknown>',
  int artistId = _androidUnknownId,
}) => TrackModel()
  ..deviceId = deviceId
  ..path = '/music/$deviceId.mp3'
  ..uri = 'content://$deviceId'
  ..title = title
  ..artist = artist
  ..artistId = artistId
  ..album = 'Download'
  ..albumId = 1
  ..genre = ''
  ..genreId = 0
  ..durationMs = 200000
  ..fileName = '$deviceId.mp3'
  ..trackNumber = 0
  ..size = 42
  ..year = 0
  ..indexedAt = DateTime(2026);

void main() {
  group('nameMissingArtist', () {
    test('reads the artist from an "Artist - Title" title', () {
      final t = _track('1', title: 'Burna Boy - Last Last')
        ..nameMissingArtist('Burna Boy - Last Last');
      expect((t.artist, t.title), ('Burna Boy', 'Last Last'));
      expect(t.artistId, TrackTags.artistIdFor('Burna Boy'));
    });

    test('keeps a real title tag when only the file name gave the artist', () {
      final t = _track('1', title: 'Last Last')
        ..nameMissingArtist('Burna Boy - Last Last (Official Video)');
      expect((t.artist, t.title), ('Burna Boy', 'Last Last'));
    });

    test('never splits a real title tag', () {
      // The file name agrees with the tag: only the artist is taken.
      final remaster = _track('1', title: 'Bohemian Rhapsody - Remastered 2011')
        ..nameMissingArtist('Queen - Bohemian Rhapsody');
      expect(
        (remaster.artist, remaster.title),
        ('Queen', 'Bohemian Rhapsody - Remastered 2011'),
      );

      // The file name says nothing, or something else: in doubt, unknown.
      for (final file in ['track01', 'Tems - Free Mind']) {
        final live = _track('2', title: 'Intro - Live')
          ..nameMissingArtist(file);
        expect((live.artist, live.title), ('<unknown>', 'Intro - Live'));
      }
    });

    test('leaves a tagged artist and an unreadable name alone', () {
      final tagged = _track('1', title: 'A - B', artist: 'Tems', artistId: 3)
        ..nameMissingArtist('A - B');
      expect(
        (tagged.artist, tagged.title, tagged.artistId),
        ('Tems', 'A - B', 3),
      );

      final plain = _track('2', title: 'Intro')..nameMissingArtist('Intro');
      expect((plain.artist, plain.artistId), ('<unknown>', _androidUnknownId));
    });
  });

  group('linkArtistIds', () {
    test('an artist read from a file name joins the same tagged artist', () {
      final tracks = [
        _track('1', title: 'Ye', artist: 'Burna Boy', artistId: 42),
        _track('2', title: 'burna boy - Last Last'),
        _track('3', title: 'Wizkid - Essence'),
      ].map((t) => t..nameMissingArtist(t.title)).toList();

      TrackModel.linkArtistIds(tracks);

      expect(
        [for (final t in tracks) t.artistId],
        [42, 42, TrackTags.artistIdFor('Wizkid')],
      );
      final artists = LibraryGrouping.artistsOf([
        for (final t in tracks) t.toEntity(),
      ]);
      expect(artists, hasLength(2));
    });
  });

  test('an album of songs by different artists has no artist', () {
    final albums = LibraryGrouping.albumsOf([
      _track('1', title: 'A', artist: 'Burna Boy', artistId: 2).toEntity(),
      _track('2', title: 'B').toEntity(),
    ]);
    expect(albums.single.artist, TrackTags.unknownArtist);
  });

  test('songs named from their files group by artist, the others stay '
      'together as unknown', () {
    final entities = [
      _track('1', title: 'Burna Boy - Last Last'),
      _track('2', title: 'Burna Boy - Ye'),
      _track('3', title: 'Wizkid - Essence'),
      _track('4', title: 'Intro'),
      _track('5', title: 'Outro', artist: 'Unknown Artist'),
    ].map((t) => (t..nameMissingArtist(t.title)).toEntity()).toList();

    final artists = {
      for (final a in LibraryGrouping.artistsOf(entities)) a.name: a.trackCount,
    };
    expect(artists, {'Burna Boy': 2, 'Wizkid': 1, TrackTags.unknownArtist: 2});
    // Older rows read as unknown too, whatever they stored.
    expect(entities.last.artist, TrackTags.unknownArtist);
  });

  group('nameUnknownArtists', () {
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
      dir = await Directory.systemTemp.createTemp('unknown_artist_test');
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

    test('names the indexed songs without an artist, and only them', () async {
      await source.insertTracks([
        _track('1', title: 'Burna Boy - Last Last')..artworkPath = '/a.jpg',
        _track('2', title: 'Tems - Me', artist: 'Tems', artistId: 3),
        _track('3', title: 'Intro'),
        _track('4', title: 'Ye', artist: 'Burna Boy', artistId: -5),
      ]);

      // What a scan reads for the same files now. Song 2 was retagged: only
      // a missing artist is filled in, other tags are not read again.
      final scanned = [
        _track('1', title: 'Burna Boy - Last Last'),
        _track('2', title: 'Me', artist: 'Tems', artistId: 3),
        _track('3', title: 'Intro'),
        // Burna Boy is tagged elsewhere now: his MediaStore id is used.
        _track('4', title: 'Ye', artist: 'Burna Boy', artistId: 42),
      ].map((t) => t..nameMissingArtist(t.title)).toList();
      await source.nameUnknownArtists(scanned);

      final stored = {
        for (final t in await source.getAllTracks())
          t.deviceId: (t.title, t.artist, t.artistId),
      };
      expect(stored, {
        '1': ('Last Last', 'Burna Boy', TrackTags.artistIdFor('Burna Boy')),
        '2': ('Tems - Me', 'Tems', 3),
        // Older rows that stay unknown are stored the current way.
        '3': ('Intro', TrackTags.unknownArtist, _androidUnknownId),
        '4': ('Ye', 'Burna Boy', 42),
      });
      // The rest of the row is kept: the cover is not extracted again.
      final first = (await source.getAllTracks()).firstWhere(
        (t) => t.deviceId == '1',
      );
      expect(first.artworkPath, '/a.jpg');
    }, skip: skip);

    test('pages built from stored rows read an older unknown artist as '
        'unknown', () async {
      await source.insertTracks([
        _track('1', title: 'Intro'),
        _track('2', title: 'Outro', artist: 'Unknown Artist'),
      ]);
      final albums = AlbumDetailRepositoryImpl(cache: source);
      final artists = ArtistDetailRepositoryImpl(cache: source);
      final search = SearchRepositoryImpl(db: source);

      final album = (await albums.getAlbumById('1')).getOrElse(() => throw 0);
      final artist = (await artists.getArtistById(
        '$_androidUnknownId',
      )).getOrElse(() => throw 0);
      final found = (await search.search('download')).getOrElse(() => throw 0);
      expect(album.artist, TrackTags.unknownArtist);
      expect(artist.name, TrackTags.unknownArtist);
      expect(found.albums.single.artist, TrackTags.unknownArtist);
    }, skip: skip);
  });
}
