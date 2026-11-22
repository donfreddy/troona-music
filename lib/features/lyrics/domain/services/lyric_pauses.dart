import 'package:troona/features/lyrics/domain/entities/lyrics.dart';

/// Adds a timed pause wherever a song goes long without a line, so the
/// screen shows the instrumental dots there instead of a line that has
/// long been sung.
///
/// An LRC line has a start and no end: how long it is sung is guessed
/// from its length. A pause is added only when enough silence is left
/// after that guess to be worth showing.
abstract final class LyricPauses {
  /// Between two lines further apart than this, a pause may come.
  static const gap = Duration(seconds: 8);

  /// The least silence worth dots.
  static const least = Duration(seconds: 4);

  /// How long [line] is taken to be sung: about ten letters a second,
  /// between two and six seconds, and a breath after it. A character of a
  /// script that writes a syllable or a word in one (Chinese, Japanese,
  /// Korean) counts for three.
  static Duration sungFor(LyricLine line) {
    var letters = 0;
    for (final rune in line.text.runes) {
      letters += rune >= _wideFrom ? 3 : 1;
    }
    final ms = (letters * 100).clamp(2000, 6000);
    return Duration(milliseconds: ms + 1000);
  }

  /// CJK radicals: from here up, the scripts counted for three.
  static const _wideFrom = 0x2E80;

  /// [lines] (sorted by time) with a pause in each long gap. Lines and
  /// pauses the file already has are kept as they are.
  static List<LyricLine> insert(List<LyricLine> lines) {
    final out = <LyricLine>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      out.add(line);
      if (line.isPause || i + 1 >= lines.length) continue;
      final next = lines[i + 1];
      if (next.isPause || next.at - line.at <= gap) continue;
      final pauseAt = line.at + sungFor(line);
      if (next.at - pauseAt < least) continue;
      out.add(LyricLine(pauseAt, ''));
    }
    return out;
  }
}
