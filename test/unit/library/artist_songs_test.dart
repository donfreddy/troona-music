import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/artist_songs.dart';

import '../../helpers/fake_player.dart';

void main() {
  test('most played first, then the songs never played by title', () {
    final songs = ArtistSongs.ranked(
      [
        testTrack('1', durationMs: 0)..title = 'b',
        testTrack('2', durationMs: 0)..title = 'Zed',
        testTrack('3', durationMs: 0)..title = 'a',
        testTrack('4', durationMs: 0)..title = 'c',
      ],
      {'2': 3, '4': 7},
    );
    expect([for (final t in songs.tracks) t.id], ['4', '2', '3', '1']);
    expect(songs.byPlays, isTrue);
  });

  test('without plays, songs are by title and not called popular', () {
    final songs = ArtistSongs.ranked([
      testTrack('1', durationMs: 0)..title = 'b',
      testTrack('2', durationMs: 0)..title = 'A',
    ], const {});
    expect([for (final t in songs.tracks) t.id], ['2', '1']);
    expect(songs.byPlays, isFalse);
  });

  test('plays of songs not by the artist change nothing', () {
    final songs = ArtistSongs.ranked(
      [testTrack('1', durationMs: 0)],
      {'other': 9},
    );
    expect(songs.byPlays, isFalse);
  });
}
