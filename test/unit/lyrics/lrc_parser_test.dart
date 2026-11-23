import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics.dart';
import 'package:troona/features/lyrics/domain/services/lrc_parser.dart';

const _src = LyricsSource.imported;

SyncedLyrics _synced(String raw) =>
    LrcParser.parse(raw, source: _src)! as SyncedLyrics;

Duration _ms(int ms) => Duration(milliseconds: ms);

void main() {
  group('stamps', () {
    test('hundredths, thousandths, tenths or none', () {
      final lyrics = _synced('[01:23.45]a\n[01:23.456]b\n[00:12.5]c\n[00:07]d');
      expect(
        [for (final l in lyrics.lines) l.at],
        [
          _ms(7000),
          _ms(12500), // .5 is half a second, not 5 ms
          _ms(83450),
          _ms(83456),
        ],
      );
    });

    test('a comma or a colon before the fraction', () {
      final lyrics = _synced('[01:23,45]a\n[01:24:45]b');
      expect(lyrics.lines.map((l) => l.at), [_ms(83450), _ms(84450)]);
    });

    test('several stamps make one line each, sorted', () {
      final lyrics = _synced('[00:12.00][00:45.00]Chorus\n[00:20.00]Verse');
      expect(lyrics.lines, const [
        LyricLine(Duration(seconds: 12), 'Chorus'),
        LyricLine(Duration(seconds: 20), 'Verse'),
        LyricLine(Duration(seconds: 45), 'Chorus'),
      ]);
    });

    test('out of order lines are sorted; a shared time keeps file order', () {
      final lyrics = _synced('[00:30.00]c\n[00:10.00]a\n[00:10.00]b');
      expect(lyrics.lines.map((l) => l.text), ['a', 'b', 'c']);
    });

    test('a stamp with no text is a pause, kept', () {
      final lyrics = _synced('[00:10.00]Sing\n[00:20.00]\n[00:40.00]Again');
      expect(lyrics.lines[1], const LyricLine(Duration(seconds: 20), ''));
      expect(lyrics.lines[1].isPause, isTrue);
    });

    test('word stamps are taken out of the text', () {
      final lyrics = _synced('[00:12.00]<00:12.50>Hello <00:13.00>world');
      expect(lyrics.lines.single.text, 'Hello world');
    });
  });

  group('tags', () {
    test('metadata is ignored', () {
      final lyrics = _synced(
        '[ar:BNXN]\n[ti:Song]\n[al:Album]\n[by:me]\n[length:03:05]\n'
        '[00:01.00]Line',
      );
      expect(lyrics.lines.single.text, 'Line');
    });

    test('the global offset, positive or negative', () {
      expect(_synced('[offset:+250]\n[00:01.00]a').offset, _ms(250));
      expect(_synced('[offset: -120]\n[00:01.00]a').offset, _ms(-120));
      expect(_synced('[00:01.00]a').offset, Duration.zero);
    });
  });

  group('plain lyrics and nothing', () {
    test('text with no stamp is plain, stanzas kept one blank line apart', () {
      final lyrics = LrcParser.parse(
        'First line\nSecond line\n\n\n\nNew stanza\n',
        source: LyricsSource.embedded,
      );
      expect(
        lyrics,
        const PlainLyrics(
          'First line\nSecond line\n\nNew stanza',
          source: LyricsSource.embedded,
        ),
      );
    });

    test('empty, blank or tags only is nothing', () {
      for (final raw in [
        '',
        '  \n\n',
        '[ar:x]\n[ti:y]',
        '[00:01.00]\n[00:02.00]',
      ]) {
        expect(LrcParser.parse(raw, source: _src), isNull, reason: raw);
      }
    });

    test('a byte order mark and Windows line ends are taken out', () {
      final lyrics = _synced('﻿[00:01.00]a\r\n[00:02.00]b\r\n');
      expect(lyrics.lines.map((l) => l.text), ['a', 'b']);
    });
  });

  group('decoding', () {
    test('UTF-8 with or without a mark', () {
      expect(LrcParser.decode(utf8.encode('Été')), 'Été');
      expect(
        LrcParser.decode([0xEF, 0xBB, 0xBF, ...utf8.encode('Été')]),
        'Été',
      );
    });

    test('UTF-16, little and big endian, by their mark', () {
      List<int> le(String s) => [
        0xFF,
        0xFE,
        for (final u in s.codeUnits) ...[u & 0xff, u >> 8],
      ];
      List<int> be(String s) => [
        0xFE,
        0xFF,
        for (final u in s.codeUnits) ...[u >> 8, u & 0xff],
      ];
      expect(LrcParser.decode(le('[00:01.00]Ça va')), '[00:01.00]Ça va');
      expect(LrcParser.decode(be('Ça')), 'Ça');
    });

    test('Latin-1 when it is not UTF-8', () {
      expect(LrcParser.decode(latin1.encode('Déjà vu')), 'Déjà vu');
    });

    test('a binary file is refused: a NUL, or control characters past '
        '1 %', () {
      expect(LrcParser.decode([...utf8.encode('[00:01.00]A'), 0]), isNull);
      // A JPEG's start, then timestamps a picture may happen to hold.
      expect(
        LrcParser.decode([
          0xFF, 0xD8, 0xFF, 0xE0, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x01, //
          ...utf8.encode('[00:01.00]Hidden'),
        ]),
        isNull,
      );
      // One stray control character in a long text is still text.
      expect(
        LrcParser.decode([...utf8.encode('[00:01.00]${'a' * 200}'), 0x07]),
        isNotNull,
      );
    });

    test('a file too big is refused', () {
      expect(
        LrcParser.decode(List.filled(LrcParser.maxBytes + 1, 0x41)),
        isNull,
      );
      expect(
        LrcParser.decode(List.filled(LrcParser.maxBytes, 0x41)),
        isNotNull,
      );
    });
  });
}
