/// A quarter of the day, six hours each so that none weighs more than
/// another: night is midnight to 6.
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
  final List<int> _cells;

  const ListeningMoments._(this._cells);

  static const none = ListeningMoments._([]);

  /// From plays per hour of the week, index `(weekday - 1) * 24 + hour`.
  factory ListeningMoments.fromHours(List<int> hourPlays) {
    if (hourPlays.every((p) => p == 0)) return none;
    final cells = List.filled(7 * DayPart.values.length, 0);
    for (var i = 0; i < hourPlays.length; i++) {
      final weekday = i ~/ 24 + 1;
      cells[_index(weekday, DayPart.of(i % 24))] += hourPlays[i];
    }
    return ListeningMoments._(cells);
  }

  static int _index(int weekday, DayPart part) =>
      (weekday - 1) * DayPart.values.length + part.index;

  bool get isEmpty => _cells.isEmpty;

  /// Plays started on [weekday] (1 for Monday) during [part].
  int playsAt(int weekday, DayPart part) =>
      isEmpty ? 0 : _cells[_index(weekday, part)];

  int get maxPlays => isEmpty ? 0 : _cells.reduce((a, b) => a > b ? a : b);

  int get total => isEmpty ? 0 : _cells.reduce((a, b) => a + b);

  /// Fewest plays before a peak means something: two plays on a Friday
  /// evening do not make a habit.
  static const minPlaysForPeak = 5;

  /// The weekday and part with the most plays; null with too few plays, or
  /// when no cell stands out (two of them tie for first).
  (int weekday, DayPart part)? get peak {
    if (total < minPlaysForPeak) return null;
    final max = maxPlays;
    (int, DayPart)? best;
    for (var weekday = 1; weekday <= 7; weekday++) {
      for (final part in DayPart.values) {
        if (playsAt(weekday, part) != max) continue;
        if (best != null) return null;
        best = (weekday, part);
      }
    }
    return best;
  }
}
