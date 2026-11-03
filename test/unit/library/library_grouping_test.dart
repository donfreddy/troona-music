import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/artist_credit.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/services/library_grouping.dart';
import 'package:troona/features/library/domain/services/track_tags.dart';

ArtistCredit _c(String name) =>
    ArtistCredit(id: TrackTags.artistIdFor(name), name: name);

Track _t(String id, List<String> artists, {int albumId = 1}) => Track(
  id: id,
  title: id,
  artist: artists.join(', '),
  artistId: TrackTags.artistIdFor(artists.first),
  credits: [for (final a in artists) _c(a)],
  album: 'Album $albumId',
  albumId: albumId,
  path: '/$id.mp3',
  uri: '',
  size: 0,
  durationMs: 0,
  fileName: '$id.mp3',
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
  });

  test('a compilation has no artist', () {
    final album = LibraryGrouping.albumsOf([
      _t('1', ['Dua Lipa']),
      _t('2', ['Drake']),
    ]).single;
    expect(album.artist, TrackTags.unknownArtist);
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
}
