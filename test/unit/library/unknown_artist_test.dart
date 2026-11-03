import 'dart:io';

import 'package:dartz/dartz.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/history/domain/repositories/play_history_repository.dart';
import 'package:troona/features/library/data/models/track_model.dart';
import 'package:troona/features/library/data/repositories/album_detail_repository_impl.dart';
import 'package:troona/features/library/data/repositories/artist_detail_repository_impl.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/services/library_grouping.dart';
import 'package:troona/features/library/presentation/bloc/artist_detail/artist_detail_bloc.dart';
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

  group('link', () {
    test('an artist read from a file name joins the same tagged artist', () {
      final tracks = [
        _track('1', title: 'Ye', artist: 'Burna Boy', artistId: 42),
        _track('2', title: 'burna boy - Last Last'),
        _track('3', title: 'Wizkid - Essence'),
      ].map((t) => t..nameMissingArtist(t.title)).toList();

      TrackModel.link(tracks);

      final burna = TrackTags.artistIdFor('Burna Boy');
      expect(
        [for (final t in tracks) t.artistId],
        [burna, burna, TrackTags.artistIdFor('Wizkid')],
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

  group('refreshIndexed', () {
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

    test('brings indexed songs up to date with their tags, keeping their '
        'cover', () async {
      // Rows as an earlier version stored them: MediaStore artist ids, an
      // unknown artist written the old way, no credits.
      await source.insertTracks([
        _track('1', title: 'Burna Boy - Last Last')..artworkPath = '/a.jpg',
        _track('2', title: 'Tems - Me', artist: 'Tems', artistId: 3),
        _track('3', title: 'Intro'),
        _track('4', title: 'Ye', artist: 'Burna Boy, Tems', artistId: 5),
      ]);

      // What a scan reads for the same files now. Song 2 was retagged.
      final scanned = [
        _track('1', title: 'Burna Boy - Last Last'),
        _track('2', title: 'Me', artist: 'Tems', artistId: 3),
        _track('3', title: 'Intro'),
        _track('4', title: 'Ye', artist: 'Burna Boy, Tems', artistId: 5),
      ].map((t) => t..nameMissingArtist(t.title)).toList();
      TrackModel.link(scanned);
      await source.refreshIndexed(scanned);

      final burna = TrackTags.artistIdFor('Burna Boy');
      final tems = TrackTags.artistIdFor('Tems');
      final stored = {
        for (final t in await source.getAllTracks())
          t.deviceId: (t.title, t.artist, t.artistIds.join(',')),
      };
      expect(stored, {
        '1': ('Last Last', 'Burna Boy', '$burna'),
        '2': ('Me', 'Tems', '$tems'),
        // Older rows that stay unknown are stored the current way.
        '3': ('Intro', TrackTags.unknownArtist, '${TrackTags.unknownArtistId}'),
        '4': ('Ye', 'Burna Boy, Tems', '$burna,$tems'),
      });
      // The rest of the row is kept: the cover is not extracted again.
      final first = (await source.getAllTracks()).firstWhere(
        (t) => t.deviceId == '1',
      );
      expect(first.artworkPath, '/a.jpg');

      // Tems' page holds the collaboration too.
      final temsSongs = await source.getTracksByArtistId(tems);
      expect({for (final t in temsSongs) t.deviceId}, {'2', '4'});
    }, skip: skip);

    test('a scan joins an album split across folders, once', () async {
      // Pinkprint saved in two folders, as MediaStore reports it.
      List<TrackModel> scan() => [
        _track('1', title: 'All Things Go', artist: 'Nicki Minaj')
          ..album = 'The Pinkprint'
          ..albumId = 10,
        _track('2', title: 'Feeling Myself', artist: 'Nicki Minaj, Beyoncé')
          ..album = 'The Pinkprint'
          ..albumId = 11,
        _track('3', title: 'Solo', artist: 'Beyoncé')
          ..album = 'Lemonade'
          ..albumId = 12,
      ];
      await source.insertTracks(scan());

      final scanned = scan();
      TrackModel.link(scanned);
      await source.refreshIndexed(scanned);

      final albums = {for (final t in await source.getAllTracks()) t.albumId};
      expect(albums, hasLength(2), reason: 'Pinkprint is one album');

      // Beyoncé's albums: her own, and the one she appears on, whole.
      final beyonce = TrackTags.artistIdFor('Beyoncé');
      final tracks = await source.getAlbumTracksByArtistId(beyonce);
      final ofArtist = LibraryGrouping.albumsOfArtist(beyonce, [
        for (final t in tracks) t.toEntity(),
      ]);
      expect(
        [for (final a in ofArtist.own) (a.name, a.trackCount)],
        [('Lemonade', 1)],
      );
      expect(
        [for (final a in ofArtist.appearsOn) (a.name, a.trackCount)],
        [('The Pinkprint', 2)],
      );

      // The next scan finds nothing to change.
      final again = scan();
      TrackModel.link(again);
      final stored = {
        for (final t in await source.getAllTracks()) t.deviceId: t,
      };
      expect(
        [for (final t in again) stored[t.deviceId]!.refreshFrom(t)],
        [false, false, false],
      );
    }, skip: skip);

    test('an artist page lists their albums and the ones they appear '
        'on', () async {
      final scanned = [
        _track('1', title: 'Feeling Myself', artist: 'Nicki Minaj, Beyoncé')
          ..album = 'The Pinkprint'
          ..albumId = 10,
        _track('2', title: 'Anaconda', artist: 'Nicki Minaj')
          ..album = 'The Pinkprint'
          ..albumId = 10,
        _track('3', title: 'Formation', artist: 'Beyoncé')
          ..album = 'Lemonade'
          ..albumId = 12,
      ];
      TrackModel.link(scanned);
      await source.insertTracks(scanned);

      final bloc = ArtistDetailBloc(
        repo: ArtistDetailRepositoryImpl(
          cache: source,
          history: _History({'1': 4}),
        ),
      )..add(ArtistDetailRequested(TrackTags.artistIdFor('Beyoncé')));
      final loaded =
          await bloc.stream.firstWhere((s) => s is ArtistDetailLoaded)
              as ArtistDetailLoaded;
      await bloc.close();

      final data = loaded.data;
      expect([for (final a in data.albums.own) a.name], ['Lemonade']);
      expect(
        [for (final a in data.albums.appearsOn) a.name],
        ['The Pinkprint'],
      );
      // Her most played song first: the section is Popular.
      expect([for (final t in data.topTracks) t.id], ['1', '3']);
      expect(data.topTracksByPlays, isTrue);
    }, skip: skip);

    test('pages built from stored rows read an older unknown artist as '
        'unknown', () async {
      await source.insertTracks([
        _track('1', title: 'Intro'),
        _track('2', title: 'Outro', artist: 'Unknown Artist'),
      ]);
      final albums = AlbumDetailRepositoryImpl(cache: source);
      final artists = ArtistDetailRepositoryImpl(
        cache: source,
        history: _History(),
      );
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

/// A history where each track of [plays] was played that many times.
final class _History implements PlayHistoryRepository {
  _History([this.plays = const {}]);
  final Map<String, int> plays;

  @override
  Future<Either<Failure, Map<String, int>>> playCounts(
    Set<String> trackIds,
  ) async => right({for (final id in trackIds) id: ?plays[id]});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
