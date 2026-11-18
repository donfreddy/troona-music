import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/artist_credit.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/services/library_grouping.dart';
import 'package:troona/features/library/domain/services/track_tags.dart';

ArtistCredit _c(String name) =>
    ArtistCredit(id: TrackTags.artistIdFor(name), name: name);

Track _t(
  String id,
  List<String> artists, {
  int albumId = 1,
  String? album,
  String? title,
  int? year,
}) => Track(
  id: id,
  title: title ?? id,
  artist: artists.join(', '),
  artistId: TrackTags.artistIdFor(artists.first),
  credits: [for (final a in artists) _c(a)],
  album: album ?? 'Album $albumId',
  albumId: albumId,
  path: '/$id.mp3',
  uri: '',
  size: 0,
  durationMs: 0,
  fileName: '$id.mp3',
  year: year,
);

void main() {
  final nicki = TrackTags.artistIdFor('Nicki Minaj');
  final beyonce = TrackTags.artistIdFor('Beyoncé');

  test('an album with guests belongs to the artist on every song', () {
    final album = LibraryGrouping.albumsOf([
      _t('1', ['Nicki Minaj']),
      _t('2', ['Nicki Minaj', 'Beyoncé']),
      _t('3', ['Drake', 'Nicki Minaj']),
    ]).single;
    expect((album.artist, album.artistId), ('Nicki Minaj', nicki));
  });

  test('an album shared by two artists on every song names both', () {
    final album = LibraryGrouping.albumsOf([
      _t('1', ['BNXN', 'Sarz']),
      _t('2', ['Sarz', 'BNXN']),
    ]).single;
    expect(album.artist, 'BNXN, Sarz');
    // Each with their own page, in the first song's order.
    expect(album.credits, [_c('BNXN'), _c('Sarz')]);
  });

  test('a comma in one name stays one credit', () {
    final tyler = ArtistCredit(
      id: TrackTags.artistIdFor('Tyler, The Creator'),
      name: 'Tyler, The Creator',
    );
    Track song(String id) => Track(
      id: id,
      title: id,
      artist: tyler.name,
      artistId: tyler.id,
      credits: [tyler],
      album: 'Igor',
      albumId: 1,
      path: '/$id.mp3',
      uri: '',
      size: 0,
      durationMs: 0,
      fileName: '$id.mp3',
    );
    final album = LibraryGrouping.albumsOf([song('1'), song('2')]).single;
    expect(album.credits, [tyler]);
  });

  test("an album's year is the first one its songs have", () {
    final albums = LibraryGrouping.albumsOf([
      _t('1', ['Burna Boy']),
      _t('2', ['Burna Boy'], year: 0),
      _t('3', ['Burna Boy'], year: 2024),
      _t('4', ['Burna Boy'], year: 2023),
      _t('5', ['Burna Boy'], albumId: 2),
    ]);
    expect([for (final a in albums) a.year], [2024, null]);
  });

  test('a compilation has no artist', () {
    final album = LibraryGrouping.albumsOf([
      _t('1', ['Dua Lipa']),
      _t('2', ['Drake']),
    ]).single;
    expect(album.artist, TrackTags.unknownArtist);
    expect(album.credits, isEmpty);
  });

  test('artists: each one credited first is listed, guests only on '
      'request, every song counts', () {
    final tracks = [
      _t('1', ['Nicki Minaj']),
      _t('2', ['Nicki Minaj', 'Beyoncé'], albumId: 2),
    ];
    final listed = LibraryGrouping.artistsOf(tracks);
    expect(
      [for (final a in listed) (a.name, a.trackCount, a.albumCount)],
      [('Nicki Minaj', 2, 2)],
    );
    final all = LibraryGrouping.artistsOf(tracks, guests: true);
    expect([for (final a in all) a.name], ['Nicki Minaj', 'Beyoncé']);

    final guest = LibraryGrouping.artistOf(beyonce, tracks)!;
    expect((guest.name, guest.trackCount), ('Beyoncé', 1));

    // Album 2, one song, is Nicki's: she is credited first. With a second
    // song crediting both, it is theirs alike; with a solo Nicki song
    // instead, Beyoncé only appears on it.
    expect(guest.albumCount, 0);
    final duo = [
      ...tracks,
      _t('4', ['Beyoncé', 'Nicki Minaj'], albumId: 2),
    ];
    expect(LibraryGrouping.artistOf(beyonce, duo)!.albumCount, 1);
    final appears = [
      ...tracks,
      _t('3', ['Nicki Minaj'], albumId: 2),
    ];
    expect(LibraryGrouping.artistOf(beyonce, appears)!.albumCount, 0);
    final nicki = LibraryGrouping.artistsOf(appears).single;
    expect((nicki.trackCount, nicki.albumCount), (3, 2));
    expect(
      LibraryGrouping.artistOf(TrackTags.artistIdFor('Drake'), tracks),
      isNull,
    );
  });

  test("an artist's own albums and the ones they appear on", () {
    final albums = LibraryGrouping.albumsOfArtist(beyonce, [
      _t('1', ['Nicki Minaj']),
      _t('2', ['Nicki Minaj', 'Beyoncé']),
      _t('3', ['Beyoncé'], albumId: 2),
    ]);
    expect([for (final a in albums.own) (a.id, a.trackCount)], [('2', 1)]);
    // The whole album counts, not only her song.
    expect(
      [for (final a in albums.appearsOn) (a.id, a.trackCount)],
      [('1', 2)],
    );
  });

  group('releases newest first', () {
    final khaid = TrackTags.artistIdFor('Khaid');

    test('by year, those without one last, in library order', () {
      final albums = LibraryGrouping.albumsOfArtist(khaid, [
        _t('1', ['Khaid'], album: 'Old', title: 'a', year: 2019),
        _t('2', ['Khaid'], albumId: 2, album: 'Undated', title: 'b'),
        _t('3', ['Khaid'], albumId: 3, album: 'New', title: 'c', year: 2024),
        _t('4', ['Khaid'], albumId: 4, album: 'Undated 2', title: 'd'),
        _t('5', ['Khaid'], albumId: 5, album: 'Mid', title: 'e', year: 2021),
      ]);
      expect(
        [for (final a in albums.own) a.name],
        ['New', 'Mid', 'Old', 'Undated', 'Undated 2'],
      );
    });

    test('the latest release is the newest album or single', () {
      final albums = LibraryGrouping.albumsOfArtist(khaid, [
        _t('1', ['Khaid'], album: 'Emotions', title: 'a', year: 2023),
        _t('2', ['Khaid'], albumId: 2, album: 'Anabella', year: 2024),
        _t('5', ['Khaid'], albumId: 5, album: 'Early', title: 'e', year: 2019),
        _t(
          '6',
          ['Khaid'],
          albumId: 6,
          album: 'Earlier',
          title: 'f',
          year: 2018,
        ),
        // Someone else's album, newer still: not theirs.
        _t('3', ['Mata', 'Khaid'], albumId: 3, album: '2039', year: 2025),
        _t('4', ['Mata'], albumId: 3, album: '2039', year: 2025),
      ]);
      expect(albums.latest?.name, 'Anabella');
    });

    test('no latest release without a year, nor under four releases', () {
      final undated = LibraryGrouping.albumsOfArtist(khaid, [
        for (var i = 1; i <= 4; i++)
          _t('$i', ['Khaid'], albumId: i, album: 'A$i', title: 't$i'),
      ]);
      expect(undated.latest, isNull);

      final three = LibraryGrouping.albumsOfArtist(khaid, [
        for (var i = 1; i <= 3; i++)
          _t(
            '$i',
            ['Khaid'],
            albumId: i,
            album: 'A$i',
            title: 't$i',
            year: 2020 + i,
          ),
      ]);
      expect(three.latest, isNull, reason: 'its cover is right below');
    });
  });

  test('an album of one song belongs to the artist credited first', () {
    final khaid = TrackTags.artistIdFor('Khaid');
    final tracks = [
      _t(
        '1',
        ['Layzee Ella', 'Khaid'],
        album: 'Medusa (feat. Khaid)',
        title: 'Medusa (feat. Khaid)',
      ),
    ];
    final album = LibraryGrouping.albumsOf(tracks).single;
    expect(album.artist, 'Layzee Ella');
    final ofKhaid = LibraryGrouping.albumsOfArtist(khaid, tracks);
    expect(ofKhaid.singles, isEmpty);
    expect(
      [for (final a in ofKhaid.appearsOn) a.name],
      ['Medusa (feat. Khaid)'],
    );
    final guest = LibraryGrouping.artistOf(khaid, tracks)!;
    expect((guest.albumCount, guest.singleCount), (0, 0));
  });

  test("an artist's albums, singles and the ones they appear on", () {
    final khaid = TrackTags.artistIdFor('Khaid');
    final tracks = [
      _t('1', ['Khaid'], album: 'Emotions', title: 'Jara'),
      _t('2', ['Khaid', 'Olamide'], album: 'Emotions', title: 'No Time'),
      _t('3', ['Khaid'], albumId: 2, album: 'Anabella', title: 'Anabella'),
      // One song of someone else's album: not a single, nor theirs.
      _t('4', ['Mata', 'Khaid'], albumId: 3, album: '2039', title: 'Kamikaze'),
      // A song of their own named otherwise: an album of theirs.
      _t('5', ['Khaid'], albumId: 4, album: 'Playboy', title: 'Diana'),
    ];
    final albums = LibraryGrouping.albumsOfArtist(khaid, tracks);
    expect([for (final a in albums.own) a.name], ['Emotions', 'Playboy']);
    expect([for (final a in albums.singles) a.name], ['Anabella']);
    expect([for (final a in albums.appearsOn) a.name], ['2039']);
    expect(albums.singles.single.isSingle, isTrue);
    expect(albums.own.first.isSingle, isFalse);

    final artist = LibraryGrouping.artistOf(khaid, tracks)!;
    expect((artist.albumCount, artist.singleCount), (2, 1));
    final listed = LibraryGrouping.artistsOf(
      tracks,
    ).firstWhere((a) => a.name == 'Khaid');
    expect((listed.albumCount, listed.singleCount), (2, 1));
  });

  test("an artist's name and cover do not hang on the order of their "
      'songs: the Library and their page show the same artist', () {
    // The same songs, as the Library reads them and as the artist page
    // does (by album and track): the name and cover of the song added
    // first (the lowest id).
    final songs = [
      _t('30', ['KHAID'], albumId: 2)..artworkPath = '/covers/b.jpg',
      _t('12', ['Khaid'])..artworkPath = '/covers/a.jpg',
      // Added first: '7' comes before '12' by number, not by text.
      _t('7', ['Khaid'])..artworkPath = '/covers/c.jpg',
    ];
    final id = TrackTags.artistIdFor('Khaid');
    for (final order in [songs, songs.reversed.toList()]) {
      final listed = LibraryGrouping.artistsOf(order).single;
      final page = LibraryGrouping.artistOf(id, order)!;
      for (final artist in [listed, page]) {
        expect((artist.name, artist.artworkPath), ('Khaid', '/covers/c.jpg'));
      }
    }
  });
}
