import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/audio_format.dart';
import 'package:troona/features/library/domain/entities/track.dart';

Track _track(String fileName, {String path = ''}) => Track(
  id: fileName,
  title: fileName,
  artist: 'a',
  artistId: 1,
  album: 'b',
  albumId: 1,
  path: path,
  uri: '',
  size: 0,
  durationMs: 0,
  fileName: fileName,
);

void main() {
  test('reads the extension case-insensitively', () {
    expect(AudioFormat.of(_track('song.FLAC')), AudioFormat.flac);
    expect(AudioFormat.of(_track('a.b.mp3')), AudioFormat.mp3);
  });

  test('falls back to the path when the file name is empty', () {
    expect(AudioFormat.of(_track('', path: '/music/x.opus')), AudioFormat.opus);
  });

  test('unknown for no extension, trailing dot or unsupported type', () {
    expect(AudioFormat.of(_track('song')), AudioFormat.unknown);
    expect(AudioFormat.of(_track('song.')), AudioFormat.unknown);
    expect(AudioFormat.of(_track('song.wma')), AudioFormat.unknown);
  });

  test('M4A is never lossless: it may hold AAC', () {
    expect(AudioFormat.m4a.lossless, isFalse);
  });

  test('allLossless needs every track lossless and at least one track', () {
    expect(AudioFormat.allLossless([]), isFalse);
    expect(
      AudioFormat.allLossless([_track('a.flac'), _track('b.wav')]),
      isTrue,
    );
    expect(
      AudioFormat.allLossless([_track('a.flac'), _track('b.mp3')]),
      isFalse,
    );
  });

  test('allOf lists distinct known formats in a stable order', () {
    expect(
      AudioFormat.allOf([
        _track('a.flac'),
        _track('b.mp3'),
        _track('c.flac'),
        _track('d.xyz'),
      ]),
      [AudioFormat.mp3, AudioFormat.flac],
    );
  });

  test('sharedBy needs one known format across every track', () {
    expect(AudioFormat.sharedBy([]), isNull);
    expect(
      AudioFormat.sharedBy([_track('a.mp3'), _track('b.MP3')]),
      AudioFormat.mp3,
    );
    expect(AudioFormat.sharedBy([_track('a.mp3'), _track('b.flac')]), isNull);
    expect(AudioFormat.sharedBy([_track('a.mp3'), _track('b.wma')]), isNull);
  });
}
