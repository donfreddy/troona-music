import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/artist_credit.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/services/album_order.dart';
import 'package:troona/features/library/domain/services/library_grouping.dart';
import 'package:troona/features/library/domain/services/track_tags.dart';

Track _t(
  String id, {
  int? number,
  String title = 'Song',
  List<String> artists = const ['Nicki Minaj'],
}) => Track(
  id: id,
  title: title,
  artist: artists.join(', '),
  artistId: TrackTags.artistIdFor(artists.first),
  credits: [
    for (final a in artists)
      ArtistCredit(id: TrackTags.artistIdFor(a), name: a),
  ],
  album: 'Album',
  albumId: 1,
  trackNumber: number,
  path: '/$id.mp3',
  uri: '',
  size: 0,
  durationMs: 0,
  fileName: '$id.mp3',
);

void main() {
  group('sorted', () {
    test('by disc, then track number', () {
      final order = AlbumOrder.sorted([
        _t('1', number: 2001),
        _t('2', number: 3),
        _t('3', number: 1),
        _t('4', number: 1002),
      ]);
      expect([for (final t in order) t.id], ['3', '2', '4', '1']);
    });

    test('without numbers, in the order the files were added', () {
      final order = AlbumOrder.sorted([
        _t('1000805277'),
        _t('1000805269'),
        _t('1000805273'),
      ]);
      expect(
        [for (final t in order) t.id],
        ['1000805269', '1000805273', '1000805277'],
      );
    });

    test('songs without a number come after the numbered ones', () {
      final order = AlbumOrder.sorted([_t('1'), _t('9', number: 4)]);
      expect([for (final t in order) t.id], ['9', '1']);
    });
  });

  group('numbers', () {
    test('track numbers when every song has one, disc left out', () {
      expect(AlbumOrder.numbers([_t('1', number: 1003), _t('2', number: 7)]), [
        3,
        7,
      ]);
    });

    test('places in the list as soon as one song has none', () {
      expect(AlbumOrder.numbers([_t('1', number: 3), _t('2'), _t('3')]), [
        1,
        2,
        3,
      ]);
    });
  });

  group('creditLine', () {
    test("nothing for the album's artist alone", () {
      expect(LibraryGrouping.creditLine(_t('1'), 'Nicki Minaj'), isNull);
    });

    test('guests the title does not name', () {
      final guest = _t('1', artists: ['Nicki Minaj', 'Beyoncé']);
      expect(
        LibraryGrouping.creditLine(guest, 'Nicki Minaj'),
        'Nicki Minaj, Beyoncé',
      );
      final named = _t(
        '2',
        title: 'Feeling Myself (feat. Beyoncé)',
        artists: ['Nicki Minaj', 'Beyoncé'],
      );
      expect(LibraryGrouping.creditLine(named, 'Nicki Minaj'), isNull);
    });

    test('every song of a compilation', () {
      final song = _t('1', artists: ['Dua Lipa']);
      expect(
        LibraryGrouping.creditLine(song, TrackTags.unknownArtist),
        'Dua Lipa',
      );
    });

    test('nothing on an album shared by two artists', () {
      final song = _t('1', artists: ['BNXN', 'Sarz']);
      expect(LibraryGrouping.creditLine(song, 'BNXN, Sarz'), isNull);
    });
  });
}
