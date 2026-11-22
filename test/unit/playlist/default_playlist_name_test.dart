import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/playlist/presentation/utils/default_playlist_name.dart';

void main() {
  String nameOf(int n) => 'My playlist #$n';
  Playlist named(String id, String name) => Playlist(id: id, name: name);

  test('the first playlist is #1', () {
    expect(defaultPlaylistName(const [], nameOf), 'My playlist #1');
  });

  test('counts the playlists there are, Likes left out', () {
    final playlists = [
      const Playlist(id: Playlist.likesId, name: 'Likes'),
      named('a', 'Road trip'),
      named('b', 'Replay November'),
    ];
    expect(defaultPlaylistName(playlists, nameOf), 'My playlist #3');
  });

  test('moves past a name taken, whatever its case', () {
    final playlists = [
      named('a', 'my playlist #2'),
      named('b', 'My playlist #3'),
    ];
    expect(defaultPlaylistName(playlists, nameOf), 'My playlist #4');
  });

  test('a lower number freed by a deletion is not reused', () {
    // #1 deleted, #2 left: the next is #2 by count, taken, so #3.
    final playlists = [named('a', 'My playlist #2')];
    expect(defaultPlaylistName(playlists, nameOf), 'My playlist #3');
  });
}
