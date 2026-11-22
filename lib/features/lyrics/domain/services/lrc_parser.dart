import 'dart:convert';

import 'package:troona/features/lyrics/domain/entities/lyrics.dart';

/// Reads LRC text: timed lines, or plain lyrics when nothing is timed.
///
/// Accepted: `[mm:ss]`, `[mm:ss.x]` to `[mm:ss.xxx]` with `.`, `,` or `:`
/// before the fraction; several stamps on one line (a chorus sung twice);
/// `[offset:±ms]`; a stamp with no text (a pause). Ignored: the other tags
/// (`[ar:]`, `[ti:]`, `[length:]`...), word stamps (`<mm:ss.xx>`), a byte
/// order mark and Windows line ends. Lines out of order are sorted, those
/// sharing a time kept in file order.
abstract final class LrcParser {
  /// Most bytes a lyrics file may have: a bigger one is not lyrics.
  static const maxBytes = 512 * 1024;

  static final _stamp = RegExp(r'\[(\d{1,3}):(\d{1,2})(?:[.:,](\d{1,3}))?\]');
  static final _tag = RegExp(r'^\[([a-zA-Z#][a-zA-Z0-9#]*):(.*)\]\s*$');
  static final _word = RegExp(r'<\d{1,3}:\d{1,2}(?:[.:,]\d{1,3})?>');

  /// The lyrics in [raw]; null when it holds none (empty, or tags only).
  static Lyrics? parse(String raw, {required LyricsSource source}) {
    final text = raw.startsWith('﻿') ? raw.substring(1) : raw;
    var offset = Duration.zero;
    final timed = <(Duration, int, String)>[];
    final plain = <String>[];
    var order = 0;
    for (final rawLine in const LineSplitter().convert(text)) {
      final line = rawLine.trim();
      final (stamps, rest) = _split(line);
      if (stamps.isNotEmpty) {
        for (final at in stamps) {
          timed.add((at, order++, rest));
        }
        continue;
      }
      final tag = _tag.firstMatch(line);
      if (tag != null) {
        if (tag[1]!.toLowerCase() == 'offset') {
          final ms = int.tryParse(tag[2]!.trim().replaceFirst('+', ''));
          if (ms != null) offset = Duration(milliseconds: ms);
        }
        continue;
      }
      plain.add(line.replaceAll(_word, '').trim());
    }
    if (timed.any((t) => t.$3.isNotEmpty)) {
      timed.sort((a, b) {
        final at = a.$1.compareTo(b.$1);
        return at != 0 ? at : a.$2.compareTo(b.$2);
      });
      return SyncedLyrics(
        [for (final (at, _, text) in timed) LyricLine(at, text)],
        source: source,
        offset: offset,
      );
    }
    final body = _collapseBlankLines(plain).trim();
    return body.isEmpty ? null : PlainLyrics(body, source: source);
  }

  /// [bytes] as text: UTF-8 (with or without a byte order mark), UTF-16
  /// when its mark says so, else Latin-1. Null past [maxBytes].
  static String? decode(List<int> bytes) {
    if (bytes.length > maxBytes) return null;
    if (bytes.length >= 2) {
      if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
        return _utf16(bytes, 2, little: true);
      }
      if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
        return _utf16(bytes, 2, little: false);
      }
    }
    final start =
        bytes.length >= 3 &&
            bytes[0] == 0xEF &&
            bytes[1] == 0xBB &&
            bytes[2] == 0xBF
        ? 3
        : 0;
    try {
      return utf8.decode(bytes.sublist(start));
    } on FormatException {
      return latin1.decode(bytes);
    }
  }

  /// Every stamp at the start of [line], then its text without word stamps.
  static (List<Duration>, String) _split(String line) {
    final stamps = <Duration>[];
    var rest = line;
    for (;;) {
      final m = _stamp.matchAsPrefix(rest);
      if (m == null) break;
      final fraction = m[3] ?? '';
      // "5" is half a second, "45" 450 ms, "456" 456 ms.
      final ms = fraction.isEmpty ? 0 : int.parse(fraction.padRight(3, '0'));
      stamps.add(
        Duration(
          minutes: int.parse(m[1]!),
          seconds: int.parse(m[2]!),
          milliseconds: ms,
        ),
      );
      rest = rest.substring(m.end).trimLeft();
    }
    return (stamps, rest.replaceAll(_word, '').trim());
  }

  static String _utf16(List<int> bytes, int start, {required bool little}) {
    final units = <int>[];
    for (var i = start; i + 1 < bytes.length; i += 2) {
      units.add(
        little ? bytes[i] | bytes[i + 1] << 8 : bytes[i] << 8 | bytes[i + 1],
      );
    }
    return String.fromCharCodes(units);
  }

  /// Stanzas kept apart by one blank line, never more.
  static String _collapseBlankLines(List<String> lines) {
    final out = <String>[];
    for (final line in lines) {
      if (line.isEmpty && (out.isEmpty || out.last.isEmpty)) continue;
      out.add(line);
    }
    return out.join('\n');
  }
}
