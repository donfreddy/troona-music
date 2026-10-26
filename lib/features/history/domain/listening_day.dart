/// Local calendar days as integers: days since 1970-01-01, read from the
/// date fields only. A day is one key whatever its length, so a daylight
/// saving change still maps to a single day.
abstract final class ListeningDay {
  /// The day [time] falls on, in the calendar of its own time zone.
  static int of(DateTime time) =>
      DateTime.utc(time.year, time.month, time.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  /// Midnight of [day], local time.
  static DateTime date(int day) {
    final utc = DateTime.fromMillisecondsSinceEpoch(
      day * Duration.millisecondsPerDay,
      isUtc: true,
    );
    return DateTime(utc.year, utc.month, utc.day);
  }

  /// The Monday starting the week of [day].
  static int weekStart(int day) => day - (weekday(day) - 1);

  /// 1 for Monday to 7 for Sunday, as [DateTime.weekday]. Day 0 is a
  /// Thursday.
  static int weekday(int day) => (day + 3) % 7 + 1;
}
