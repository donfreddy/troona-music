import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/services/library_grouping.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';

Track _t(
  String id, {
  String title = 't',
  String artist = 'artist',
  int artistId = 1,
  String album = 'album',
  int albumId = 1,
  DateTime? added,
  String? artwork,
}) => Track(
  id: id,
  title: title,
  artist: artist,
  artistId: artistId,
  album: album,
  albumId: albumId,
  path: '/$id.mp3',
  uri: '',
  size: 0,
  durationMs: 0,
  fileName: '$id.mp3',
  dateAdded: added,
  artworkPath: artwork,
);

(List<Track>, List<dynamic>, List<dynamic>) _view(
  List<Track> tracks, {
  String query = '',
  LibraryFilter filter = LibraryFilter.all,
  LibrarySort sort = LibrarySort.title,
}) => applyLibraryView(
  tracks: tracks,
  albums: LibraryGrouping.albumsOf(tracks),
  artists: LibraryGrouping.artistsOf(tracks),
  query: query,
  filter: filter,
  sort: sort,
);

void main() {
  group('applyLibraryView', () {
    test('never reorders the input list', () {
      final tracks = [_t('1', title: 'b'), _t('2', title: 'a')];
      final before = List.of(tracks);
      final (visible, _, _) = _view(tracks);
      expect(visible.map((t) => t.id), ['2', '1']);
      expect(tracks, before, reason: 'allTracks keeps its own order');
      expect(identical(visible, tracks), isFalse);
    });

    test('date added puts the newest first and undated songs last', () {
      final tracks = [
        _t('old', added: DateTime(2020)),
        _t('none'),
        _t('new', added: DateTime(2024)),
      ];
      final (visible, _, _) = _view(tracks, sort: LibrarySort.dateAdded);
      expect(visible.map((t) => t.id), ['new', 'old', 'none']);
    });

    test('switching sort back and forth gives the same result', () {
      final tracks = [
        _t('1', title: 'b', added: DateTime(2021)),
        _t('2', title: 'a', added: DateTime(2022)),
      ];
      final first = _view(tracks, sort: LibrarySort.dateAdded).$1;
      _view(tracks, sort: LibrarySort.title);
      final again = _view(tracks, sort: LibrarySort.dateAdded).$1;
      expect(again.map((t) => t.id), first.map((t) => t.id));
    });

    test('title sort ignores case', () {
      final tracks = [_t('1', title: 'beta'), _t('2', title: 'Alpha')];
      expect(_view(tracks).$1.map((t) => t.id), ['2', '1']);
    });

    test('title sort folds accents and ignores a leading "The"', () {
      final tracks = [
        _t('zebra', title: 'Zebra'),
        _t('ete', title: 'Été'),
        _t('beatles', title: 'The Beatles'),
      ];
      expect(_view(tracks).$1.map((t) => t.id), ['beatles', 'ete', 'zebra']);
    });

    test('query matches title, artist or album, case-insensitively', () {
      final tracks = [
        _t('1', title: 'Hello'),
        _t('2', artist: 'HELLOWORLD', artistId: 2),
        _t('3', album: 'other', albumId: 3),
      ];
      expect(_view(tracks, query: ' hello ').$1.map((t) => t.id), ['1', '2']);
    });

    test('a filter empties the other sections', () {
      final tracks = [_t('1')];
      final (t, al, ar) = _view(tracks, filter: LibraryFilter.albums);
      expect(t, isEmpty);
      expect(al, hasLength(1));
      expect(ar, isEmpty);
    });
  });

  group('LibraryGrouping', () {
    test('albums with the same name but different ids stay apart', () {
      final albums = LibraryGrouping.albumsOf([
        _t('1', album: 'Greatest Hits', albumId: 10, artist: 'A'),
        _t('2', album: 'Greatest Hits', albumId: 20, artist: 'B'),
        _t('3', album: 'Greatest Hits', albumId: 10, artist: 'A'),
      ]);
      expect(albums.map((a) => (a.id, a.artist, a.trackCount)), [
        ('10', 'A', 2),
        ('20', 'B', 1),
      ]);
    });

    test('takes the first available cover, not only the first track', () {
      final albums = LibraryGrouping.albumsOf([
        _t('1'),
        _t('2', artwork: '/cover.jpg'),
      ]);
      expect(albums.single.artworkPath, '/cover.jpg');
    });

    test('artists count distinct albums', () {
      final artists = LibraryGrouping.artistsOf([
        _t('1', albumId: 1),
        _t('2', albumId: 1),
        _t('3', albumId: 2),
      ]);
      expect(artists.single.albumCount, 2);
      expect(artists.single.trackCount, 3);
    });
  });
}
