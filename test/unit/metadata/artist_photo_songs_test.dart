import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/services/metadata/artist_artwork_prefetch_service.dart';

Track _track(String id, String title, {int artistId = 1}) => Track(
  id: id,
  title: title,
  artist: 'Artist',
  artistId: artistId,
  album: 'Album',
  albumId: 1,
  path: '/music/$id.mp3',
  uri: 'content://$id',
  size: 1,
  durationMs: 180000,
  fileName: '$id.mp3',
);

void main() {
  test('the songs they lead, in the order given, each title once', () {
    final titles = ArtistArtworkPrefetchService.songTitlesFor('1', [
      _track('a', 'Most Played'),
      _track('b', 'As A Guest', artistId: 2),
      _track('c', ' Most Played '),
      _track('d', '   '),
      _track('e', 'Second'),
    ]);
    expect(titles, ['Most Played', 'Second']);
  });

  test('one search per song: versions and empty titles are skipped', () {
    final titles = ArtistArtworkPrefetchService.songTitlesFor('1', [
      _track('a', '(Interlude)'),
      _track('b', 'Song'),
      _track('c', 'Song (Live)'),
      _track('d', 'Other'),
    ]);
    expect(titles, ['Song', 'Other']);
  });

  test('none for a guest only', () {
    expect(
      ArtistArtworkPrefetchService.songTitlesFor('1', [
        _track('a', 'Theirs', artistId: 2),
      ]),
      isEmpty,
    );
  });
}
