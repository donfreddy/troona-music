import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist_albums.dart';

Album _album(String id, {bool single = false, int? year}) => Album(
  id: id,
  name: 'Album $id',
  artist: 'Khaid',
  artistId: 1,
  trackCount: single ? 1 : 10,
  isSingle: single,
  year: year,
);

void main() {
  List<Album> albums(int n) => [for (var i = 0; i < n; i++) _album('a$i')];
  List<Album> singles(int n) => [
    for (var i = 0; i < n; i++) _album('s$i', single: true),
  ];

  test('under five releases, albums and singles make one discography, '
      'albums first', () {
    final few = ArtistAlbums(own: albums(2), singles: singles(2));
    expect(few.oneDiscography, isTrue);
    expect([for (final a in few.releases) a.id], ['a0', 'a1', 's0', 's1']);
  });

  test('from five releases, two sections', () {
    expect(
      ArtistAlbums(own: albums(3), singles: singles(2)).oneDiscography,
      isFalse,
    );
  });

  test('albums alone, or singles alone, keep their own title', () {
    expect(ArtistAlbums(own: albums(2)).oneDiscography, isFalse);
    expect(ArtistAlbums(singles: singles(2)).oneDiscography, isFalse);
  });

  test('the albums they appear on stay apart', () {
    final albumsOf = ArtistAlbums(
      own: albums(1),
      singles: singles(1),
      appearsOn: [_album('x')],
    );
    expect(albumsOf.oneDiscography, isTrue);
    expect([for (final a in albumsOf.releases) a.id], ['a0', 's0']);
  });

  test('one discography reads newest first, albums and singles mixed, the '
      'undated last, an album before a single of its year', () {
    final releases = ArtistAlbums(
      own: [_album('a2019', year: 2019), _album('a2023', year: 2023)],
      singles: [
        _album('undated', single: true),
        _album('s2023', single: true, year: 2023),
        _album('s2021', single: true, year: 2021),
      ],
    );
    expect([for (final a in releases.discography) a.id], [
      'a2023',
      's2023',
      's2021',
      'a2019',
      'undated',
    ]);
  });
}
