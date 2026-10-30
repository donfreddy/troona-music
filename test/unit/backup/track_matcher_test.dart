import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/backup/domain/track_matcher.dart';
import 'package:troona/features/library/domain/entities/track.dart';

Track _track(
  String id, {
  String title = 'Song',
  String artist = 'Artist',
  String album = 'Album',
  int durationMs = 200000,
  String fileName = 'song.mp3',
  int size = 1000,
}) => Track(
  id: id,
  title: title,
  artist: artist,
  artistId: 1,
  album: album,
  albumId: 1,
  path: '/music/$fileName',
  uri: 'content://$id',
  size: size,
  durationMs: durationMs,
  fileName: fileName,
);

BackupTrack _saved({
  String title = 'Song',
  String artist = 'Artist',
  String album = 'Album',
  int durationMs = 200000,
  String fileName = 'song.mp3',
  int size = 1000,
}) => BackupTrack(
  title: title,
  artist: artist,
  album: album,
  durationMs: durationMs,
  fileName: fileName,
  size: size,
);

void main() {
  test('a copied file is found by its name and size', () {
    final matcher = TrackMatcher([
      _track('1', title: 'Retagged', fileName: 'a.flac', size: 42),
    ]);

    expect(matcher.match(_saved(fileName: 'a.flac', size: 42)), '1');
  });

  test('a file of another size falls back to its tags', () {
    final matcher = TrackMatcher([_track('1', fileName: 'a.mp3', size: 7)]);

    expect(matcher.match(_saved(fileName: 'a.flac', size: 42)), '1');
  });

  test('tags ignore case and spacing', () {
    final matcher = TrackMatcher([
      _track('1', title: 'the  song ', artist: 'ARTIST', fileName: 'x'),
    ]);

    expect(matcher.match(_saved(title: 'The Song', fileName: 'y')), '1');
  });

  test('a renamed album is found by title and artist', () {
    final matcher = TrackMatcher([
      _track('1', album: 'Deluxe Edition', fileName: 'x'),
    ]);

    expect(matcher.match(_saved(fileName: 'y')), '1');
  });

  test('the album decides between two versions of a title', () {
    final matcher = TrackMatcher([
      _track('live', album: 'Live', fileName: 'x'),
      _track('studio', fileName: 'y'),
    ]);

    expect(matcher.match(_saved(fileName: 'z')), 'studio');
  });

  test('a duration beyond the tolerance is another song', () {
    final matcher = TrackMatcher([
      _track('1', durationMs: 200000 + 2001, fileName: 'x'),
    ]);

    expect(matcher.match(_saved(fileName: 'y')), isNull);
  });

  test('a duration within the tolerance matches', () {
    final matcher = TrackMatcher([
      _track('1', durationMs: 200000 - 2000, fileName: 'x'),
    ]);

    expect(matcher.match(_saved(fileName: 'y')), '1');
  });

  test('the closest duration wins', () {
    final matcher = TrackMatcher([
      _track('far', durationMs: 201500, fileName: 'x'),
      _track('near', durationMs: 200400, fileName: 'y'),
    ]);

    expect(matcher.match(_saved(fileName: 'z')), 'near');
  });

  test('a tie matches nothing', () {
    final matcher = TrackMatcher([
      _track('1', durationMs: 201000, fileName: 'x'),
      _track('2', durationMs: 199000, fileName: 'y'),
    ]);

    expect(matcher.match(_saved(fileName: 'z')), isNull);
  });

  test('a stricter step wins over a closer duration', () {
    final matcher = TrackMatcher([
      _track('copy', durationMs: 203000, fileName: 'a.mp3', size: 5),
      _track('tagged', fileName: 'b.mp3'),
    ]);

    expect(matcher.match(_saved(fileName: 'a.mp3', size: 5)), 'copy');
  });

  test('an unknown song is not found', () {
    final matcher = TrackMatcher([_track('1')]);

    expect(
      matcher.match(_saved(title: 'Other', fileName: 'other.mp3')),
      isNull,
    );
  });

  test('the same file in two folders takes the first copy', () {
    final matcher = TrackMatcher([
      _track('1', fileName: 'a.mp3', size: 5),
      _track('2', fileName: 'a.mp3', size: 5),
    ]);

    expect(matcher.match(_saved(fileName: 'a.mp3', size: 5)), '1');
  });

  test('a title alone does not match an unknown artist', () {
    final matcher = TrackMatcher([
      _track(
        '1',
        title: 'Intro',
        artist: '<unknown>',
        album: 'A',
        fileName: 'x',
      ),
    ]);

    expect(
      matcher.match(
        _saved(title: 'Intro', artist: '<unknown>', album: 'B', fileName: 'y'),
      ),
      isNull,
    );
  });
}
