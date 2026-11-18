import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/playlist/presentation/widgets/playlist_mosaic.dart';

/// Song [id] of album [album]; its cover is a file of its own, as the
/// scanner stores them, unless [cover] says otherwise.
Track _song(String id, int album, {String? cover}) => Track(
  id: id,
  title: 'Song $id',
  artist: 'Artist',
  artistId: 1,
  album: 'Album $album',
  albumId: album,
  path: '/music/$id.mp3',
  uri: 'content://$id',
  size: 1,
  durationMs: 1000,
  fileName: '$id.mp3',
  artworkPath: cover ?? '/covers/$id.jpg',
);

void main() {
  List<String> covers(List<Track> songs, {List<String>? order}) =>
      PlaylistMosaic.coversOf(order ?? [for (final s in songs) s.id], songs);

  test('four albums: one cover each, in the playlist order', () {
    final songs = [
      _song('a', 1),
      _song('b', 2),
      _song('c', 3),
      _song('d', 4),
      _song('e', 5),
    ];
    expect(covers(songs, order: ['d', 'c', 'b', 'a', 'e']), [
      '/covers/d.jpg',
      '/covers/c.jpg',
      '/covers/b.jpg',
      '/covers/a.jpg',
    ]);
  });

  test('songs of one album count once, though each has its own file', () {
    final songs = [
      _song('a1', 1),
      _song('a2', 1),
      _song('a3', 1),
      _song('a4', 1),
    ];
    expect(covers(songs), ['/covers/a1.jpg']);
  });

  test('two or three albums: the first cover alone, nothing repeats', () {
    final songs = [_song('a', 1), _song('b', 2), _song('b2', 2), _song('c', 3)];
    expect(covers(songs), ['/covers/a.jpg']);
  });

  test('songs without a cover, or no longer in the library, are passed', () {
    final songs = [
      _song('none', 9, cover: ''),
      _song('a', 1),
      _song('b', 2),
      _song('c', 3),
      _song('d', 4),
    ];
    expect(covers(songs, order: ['gone', 'none', 'a', 'b', 'c', 'd']), [
      '/covers/a.jpg',
      '/covers/b.jpg',
      '/covers/c.jpg',
      '/covers/d.jpg',
    ]);
    expect(covers([_song('none', 9, cover: '')]), isEmpty);
  });
}
