import 'package:troona/features/lyrics/domain/entities/lyrics.dart';

/// The line being sung at [position], -1 before the first one. [hint] is
/// the last answer: playback moves on a line at a time, so it is right or
/// one short almost always (two comparisons); a seek falls back to a binary
/// search. Of lines sharing a time, the last one is active.
int activeLineAt(List<LyricLine> lines, Duration position, {int hint = -1}) {
  bool holds(int i) =>
      (i < 0 || lines[i].at <= position) &&
      (i + 1 >= lines.length || position < lines[i + 1].at);
  if (hint >= -1 && hint < lines.length && holds(hint)) return hint;
  if (hint + 1 >= 0 && hint + 1 < lines.length && holds(hint + 1)) {
    return hint + 1;
  }
  var low = 0, high = lines.length - 1, found = -1;
  while (low <= high) {
    final mid = (low + high) >> 1;
    if (lines[mid].at <= position) {
      found = mid;
      low = mid + 1;
    } else {
      high = mid - 1;
    }
  }
  return found;
}
