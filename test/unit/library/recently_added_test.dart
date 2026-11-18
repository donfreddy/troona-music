import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/services/recently_added.dart';

import '../../helpers/fake_player.dart';

Track _song(String id, String title, {int? day, int? album}) {
  final t = testTrack(id, durationMs: 1000);
  return Track(
    id: id,
    title: title,
    artist: t.artist,
    artistId: t.artistId,
    album: t.album,
    albumId: album ?? t.albumId,
    path: t.path,
    uri: t.uri,
    size: t.size,
    durationMs: t.durationMs,
    fileName: t.fileName,
    dateAdded: day == null ? null : DateTime(2026, 1, day),
  );
}

void main() {
  List<String> ids(List<Track> tracks) => [for (final t in tracks) t.id];

  test('newest first, songs without a date last', () {
    final songs = [
      _song('old', 'A', day: 1),
      _song('none', 'B'),
      _song('new', 'C', day: 9),
    ];
    expect(ids(RecentlyAdded.of(songs)), ['new', 'old', 'none']);
  });

  test('added together: by title, accents folded', () {
    final songs = [
      _song('z', 'Zebra', day: 3),
      _song('e', 'Été', day: 3),
      _song('a', 'apple', day: 3),
    ];
    expect(ids(RecentlyAdded.of(songs)), ['a', 'e', 'z']);
  });

  test('at most the limit asked, the newest', () {
    final songs = [for (var d = 1; d <= 9; d++) _song('$d', 'S', day: d)];
    expect(ids(RecentlyAdded.of(songs, limit: 3)), ['9', '8', '7']);
    expect(RecentlyAdded.of(songs, limit: 50), hasLength(9));
  });

  test('the list given is left as it was', () {
    final songs = [_song('old', 'A', day: 1), _song('new', 'B', day: 2)];
    RecentlyAdded.of(songs);
    expect(ids(songs), ['old', 'new']);
  });

  group('albums', () {
    Album album(int id) => Album(
      id: '$id',
      name: 'Album $id',
      artist: '',
      artistId: 0,
      trackCount: 1,
    );
    List<String> albumIds(List<Album> albums) => [for (final a in albums) a.id];
    final library = [album(1), album(2), album(3)];

    test('an album comes when its newest song does', () {
      final songs = [
        _song('a', 'A', day: 1, album: 1),
        _song('b', 'B', day: 5, album: 2),
        // Album 1 got a song later than album 2's.
        _song('c', 'C', day: 7, album: 1),
        _song('d', 'D', day: 3, album: 3),
      ];
      expect(albumIds(RecentlyAdded.albumsOf(songs, library)), ['1', '2', '3']);
    });

    test("the library's own albums, as the Library shows them", () {
      final songs = [_song('a', 'A', day: 1, album: 2)];
      expect(RecentlyAdded.albumsOf(songs, library).single, same(library[1]));
    });

    test('at most the limit asked, the newest', () {
      final songs = [
        for (var d = 1; d <= 3; d++) _song('$d', 'S', day: d, album: d),
      ];
      expect(albumIds(RecentlyAdded.albumsOf(songs, library, limit: 2)), [
        '3',
        '2',
      ]);
    });

    test('a song whose album the library does not hold is passed over', () {
      final songs = [
        _song('x', 'X', day: 9, album: 99),
        _song('a', 'A', day: 1, album: 1),
      ];
      expect(albumIds(RecentlyAdded.albumsOf(songs, library, limit: 1)), ['1']);
    });
  });
}
