import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/services/album_merge.dart';
import 'package:troona/features/library/domain/services/track_tags.dart';

AlbumMember _m(int albumId, String album, List<String> artists) => (
  albumId: albumId,
  album: album,
  artistIds: [for (final a in artists) TrackTags.artistIdFor(a)],
);

void main() {
  group('albumIds', () {
    test('an album saved in several folders is one album again', () {
      // The Pinkprint as a downloader saved it: five songs per folder.
      final members = [
        _m(1, 'The Pinkprint', ['Nicki Minaj']),
        _m(1, 'The Pinkprint', ['Nicki Minaj', 'Jeremih']),
        _m(2, 'The Pinkprint', ['Nicki Minaj', 'Beyoncé']),
        _m(2, 'The Pinkprint', ['Nicki Minaj']),
        _m(3, 'the pinkprint ', ['Nicki Minaj', 'Drake', 'Lil Wayne']),
      ];
      final ids = AlbumMerge.albumIds(members);
      expect(ids.toSet(), hasLength(1));
      expect(ids.first, isNegative, reason: 'not one of the MediaStore ids');
    });

    test('a guest listed first still joins the album', () {
      final ids = AlbumMerge.albumIds([
        _m(1, 'Nu King', ['Jason Derulo']),
        _m(2, 'Nu King', ['Tesher', 'Jason Derulo']),
        _m(2, 'Nu King', ['Jason Derulo', 'Lay Bankz']),
      ]);
      expect(ids.toSet(), hasLength(1));
    });

    test('singles of one album, each in its own folder, join', () {
      final ids = AlbumMerge.albumIds([
        _m(1, 'Emotions', ['Khaid']),
        _m(2, 'Emotions', ['Khaid']),
        _m(3, 'Emotions', ['Khaid', 'Olamide']),
      ]);
      expect(ids.toSet(), hasLength(1));
    });

    test('an album keeps its id as folders come and go', () {
      final two = AlbumMerge.albumIds([
        _m(1, 'X', ['A', 'B']),
        _m(2, 'X', ['A', 'B']),
      ]);
      final three = AlbumMerge.albumIds([
        _m(1, 'X', ['A', 'B']),
        _m(2, 'X', ['A', 'B']),
        _m(3, 'X', ['A']),
      ]);
      final one = AlbumMerge.albumIds([
        _m(1, 'X', ['A', 'B']),
      ]);
      expect({...two, ...three, ...one}, hasLength(1));
      expect(one.single, isNegative, reason: 'not the MediaStore id');
    });

    test('albums sharing an artist join however they chain', () {
      // {A, B} and {A} share A, {A, B} and {B} share B: one album.
      final ids = AlbumMerge.albumIds([
        _m(1, 'X', ['A', 'B']),
        _m(1, 'X', ['A', 'B']),
        _m(2, 'X', ['A']),
        _m(3, 'X', ['B']),
      ]);
      expect(ids.toSet(), hasLength(1));
    });

    test('albums of the same name by different artists stay apart', () {
      final ids = AlbumMerge.albumIds([
        _m(1, 'Greatest Hits', ['Queen']),
        _m(2, 'Greatest Hits', ['ABBA']),
      ]);
      expect(ids[0], isNot(ids[1]));
    });

    test('a compilation is never cut, nor joined to another folder', () {
      final ids = AlbumMerge.albumIds([
        _m(1, 'Now 99', ['Dua Lipa']),
        _m(1, 'Now 99', ['Drake']),
        _m(1, 'Now 99', ['Burna Boy']),
        _m(2, 'Now 99', ['Dua Lipa']),
      ]);
      // The compilation keeps the id Android gave its folder.
      expect(ids.take(3), [1, 1, 1]);
      expect(ids[3], isNot(1));
    });

    test('songs without an artist are never joined', () {
      final ids = AlbumMerge.albumIds([
        _m(1, 'Download', [TrackTags.unknownArtist]),
        _m(2, 'download', [TrackTags.unknownArtist]),
      ]);
      expect(ids, [1, 2]);
    });

    test('the joined id is the same whatever the order of the folders', () {
      final members = [
        _m(1, 'ZUKO!', ['Fireboy DML']),
        _m(2, 'ZUKO!', ['Fireboy DML', 'Masicka']),
        _m(3, 'ZUKO!', ['Fireboy DML']),
      ];
      final ids = AlbumMerge.albumIds(members);
      final reversed = AlbumMerge.albumIds(members.reversed.toList());
      expect(reversed.reversed, ids);
    });
  });
}
