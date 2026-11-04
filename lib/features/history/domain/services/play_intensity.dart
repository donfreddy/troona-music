/// How much a day was listened to, as five steps from none (0) to a lot (4),
/// for the recap calendar's colours.
///
/// The steps are fixed counts of plays, not quartiles of the span: a colour
/// means the same in every week and month, and a quiet month does not paint
/// its busiest day as a big one. Plays, not minutes: the days rebuilt from
/// the old history have plays but no listening time.
abstract final class PlayIntensity {
  /// The fewest plays of steps 1 to 4.
  static const thresholds = [1, 5, 15, 30];

  static const maxLevel = 4;

  static int levelOf(int plays) {
    var level = 0;
    for (final t in thresholds) {
      if (plays >= t) level++;
    }
    return level;
  }

  /// [value] against the largest of its set ([max]), as a step from 1 to 4,
  /// 0 for nothing: where only the shape matters, not the volume.
  static int relativeLevelOf(num value, num max) {
    if (value <= 0 || max <= 0) return 0;
    // Rates are doubles: 21/5 against 28/5 is 3.0000000000000004 steps.
    return (value / max * maxLevel - 1e-9).ceil().clamp(1, maxLevel);
  }
}
