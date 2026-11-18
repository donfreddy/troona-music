import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/metadata/data/sources/deezer_artist_match.dart';

const _photo =
    'https://cdn-images.dzcdn.net/images/artist/'
    '638e69b9caaf9f9f3f8826febea7b543/1000x1000-000000-80-0-0.jpg';
const _silhouette =
    'https://cdn-images.dzcdn.net/images/artist//1000x1000-000000-80-0-0.jpg';

Map<String, Object?> _song(
  String title, {
  String artist = 'Daft Punk',
  String? short,
  String picture = _photo,
}) => {
  'title': title,
  'title_short': ?short,
  'artist': {'name': artist, 'picture_xl': picture},
};

void main() {
  group('photoIn', () {
    test('takes the photo of the artist whose song it is', () {
      expect(
        DeezerArtistMatch.photoIn(
          [_song('One More Time')],
          'Daft Punk',
          'One More Time',
        ),
        _photo,
      );
    });

    test('skips a namesake whose songs are not the one looked for', () {
      // Same name, other person: none of their songs is in the library.
      expect(
        DeezerArtistMatch.photoIn(
          [_song('Something Else'), _song('Another One')],
          'Daft Punk',
          'One More Time',
        ),
        isNull,
      );
    });

    test('skips the song by another artist, takes the right one after', () {
      expect(
        DeezerArtistMatch.photoIn(
          [
            _song('One More Time', artist: 'A Cover Band', picture: 'x'),
            _song('One More Time'),
          ],
          'Daft Punk',
          'One More Time',
        ),
        _photo,
      );
    });

    test('no photo for an artist Deezer shows as a silhouette', () {
      expect(
        DeezerArtistMatch.photoIn(
          [_song('One More Time', picture: _silhouette)],
          'Daft Punk',
          'One More Time',
        ),
        isNull,
      );
    });

    test('reads the short title, without the version', () {
      expect(
        DeezerArtistMatch.photoIn(
          [_song('One More Time (Short Radio Edit)', short: 'One More Time')],
          'Daft Punk',
          'One More Time - Remastered',
        ),
        _photo,
      );
    });

    test('compares names without case, accents nor punctuation', () {
      expect(
        DeezerArtistMatch.photoIn(
          [_song('Déjà Vu', artist: 'Beyoncé')],
          'BEYONCE',
          'deja vu',
        ),
        _photo,
      );
      expect(
        DeezerArtistMatch.photoIn(
          [_song('Song', artist: 'Tyler, The Creator')],
          'Tyler The Creator',
          'Song',
        ),
        _photo,
      );
    });

    test('decomposed accents, vowel signs and other scripts match', () {
      // "Renée" with its accent as a combining mark, against the composed one.
      expect(
        DeezerArtistMatch.photoIn(
          [_song('Song', artist: 'Ren\u00e9e')],
          'Rene\u0301e',
          'Song',
        ),
        _photo,
      );
      // Arabic with and without its vowel signs.
      expect(
        DeezerArtistMatch.nameKey(
          '\u0645\u064f\u062d\u064e\u0645\u064e\u0651\u062f',
        ),
        DeezerArtistMatch.nameKey('\u0645\u062d\u0645\u062f'),
      );
      expect(DeezerArtistMatch.nameKey('Łukasz Šeška'), 'lukasz seska');
      expect(
        DeezerArtistMatch.photoIn(
          [_song('Звезда по имени Солнце', artist: 'Кино')],
          'кино',
          'Звезда по имени Солнце',
        ),
        _photo,
      );
    });

    test('a featured artist in the title does not matter', () {
      expect(
        DeezerArtistMatch.photoIn(
          [_song('Song (feat. Someone)')],
          'Daft Punk',
          'Song feat. Someone',
        ),
        _photo,
      );
    });

    test('ignores malformed results and empty names', () {
      expect(
        DeezerArtistMatch.photoIn(
          [
            null,
            'text',
            {'title': 'One More Time'},
            {'artist': 'x'},
          ],
          'Daft Punk',
          'One More Time',
        ),
        isNull,
      );
      expect(
        DeezerArtistMatch.photoIn([_song('!!!')], 'Daft Punk', '!!!'),
        isNull,
      );
    });
  });

  group('pictureOf', () {
    test('largest picture with an image hash', () {
      expect(
        DeezerArtistMatch.pictureOf({
          'picture_xl': _silhouette,
          'picture_big': _photo,
        }),
        _photo,
      );
      expect(DeezerArtistMatch.pictureOf({'picture_xl': _silhouette}), isNull);
      expect(DeezerArtistMatch.pictureOf({}), isNull);
    });
  });

  test('the query is plain words, without quotes', () {
    expect(
      DeezerArtistMatch.query(' Daft Punk ', 'One "More" Time'),
      'Daft Punk One More Time',
    );
  });
}
