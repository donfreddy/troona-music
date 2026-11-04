/// A quarter of the day, six hours each so that none weighs more than
/// another. Night runs from midnight to 6 and belongs to the evening
/// before: Saturday at 2 is Friday night.
enum DayPart {
  morning(6),
  afternoon(12),
  evening(18),
  night(0);

  /// The first hour of the part, local time.
  final int firstHour;
  const DayPart(this.firstHour);

  static const hours = 6;

  static DayPart of(int hour) => switch (hour) {
    < 6 => night,
    < 12 => morning,
    < 18 => afternoon,
    _ => evening,
  };
}

/// When the plays of a span started: per weekday (Monday first) and
/// [DayPart], "When you listen".
final class ListeningMoments {
  /// Plays per cell: index `(weekday - 1) * 4 + part.index`.
  final List<int> _plays;

  /// How many times each cell's hours occur in the span: a month has five
  /// of some weekdays and four of the others.
  final List<int> _occurrences;

  const ListeningMoments._(this._plays, this._occurrences);

  static const none = ListeningMoments._([], []);

  /// From plays per hour of the week, index `(weekday - 1) * 24 + hour`,
  /// and how many of each weekday the span holds ([weekdayCounts], Monday
  /// first; one of each by default).
  factory ListeningMoments.fromHours(
    List<int> hourPlays, {
    List<int>? weekdayCounts,
  }) {
    if (hourPlays.every((p) => p == 0)) return none;
    final counts = weekdayCounts ?? List.filled(7, 1);
    final parts = DayPart.values.length;
    final plays = List.filled(7 * parts, 0);
    final occurrences = List.filled(7 * parts, 0);
    for (var weekday = 1; weekday <= 7; weekday++) {
      for (final part in DayPart.values) {
        // A night's hours fall on the next day.
        final day = part == DayPart.night ? weekday % 7 + 1 : weekday;
        occurrences[_index(weekday, part)] = counts[day - 1];
      }
    }
    for (var i = 0; i < hourPlays.length; i++) {
      final part = DayPart.of(i % 24);
      final day = i ~/ 24 + 1;
      final weekday = part == DayPart.night ? (day + 5) % 7 + 1 : day;
      plays[_index(weekday, part)] += hourPlays[i];
    }
    return ListeningMoments._(plays, occurrences);
  }

  static int _index(int weekday, DayPart part) =>
      (weekday - 1) * DayPart.values.length + part.index;

  bool get isEmpty => _plays.isEmpty;

  /// Plays started on [weekday] (1 for Monday) during [part]; a night is
  /// the one after [weekday].
  int playsAt(int weekday, DayPart part) =>
      isEmpty ? 0 : _plays[_index(weekday, part)];

  /// [playsAt] per occurrence in the span: what the steps and the peak
  /// compare, so a weekday the month holds five times does not win for it.
  double rateAt(int weekday, DayPart part) {
    if (isEmpty) return 0;
    final i = _index(weekday, part);
    return _occurrences[i] == 0 ? 0 : _plays[i] / _occurrences[i];
  }

  double get maxRate {
    var max = 0.0;
    for (var weekday = 1; weekday <= 7; weekday++) {
      for (final part in DayPart.values) {
        final rate = rateAt(weekday, part);
        if (rate > max) max = rate;
      }
    }
    return max;
  }

  int get total => isEmpty ? 0 : _plays.reduce((a, b) => a + b);

  /// Fewest plays before a peak means something: two plays on a Friday
  /// evening do not make a habit.
  static const minPlaysForPeak = 5;

  /// The weekday and part with the highest [rateAt]; null with too few
  /// plays, or when no cell stands out (two of them tie for first).
  (int weekday, DayPart part)? get peak {
    if (total < minPlaysForPeak) return null;
    final max = maxRate;
    (int, DayPart)? best;
    for (var weekday = 1; weekday <= 7; weekday++) {
      for (final part in DayPart.values) {
        if (rateAt(weekday, part) != max) continue;
        if (best != null) return null;
        best = (weekday, part);
      }
    }
    return best;
  }
}
