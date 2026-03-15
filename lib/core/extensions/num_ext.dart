import 'package:troona/features/library/domain/entities/track.dart';

extension IntExt on int {
  int getTotalInt(List<Track> tracks) {
    int total = 0;

    for (var s in tracks) {
      total += s.durationMs;
    }

    return total;
  }
}

extension NullableIntExt on int? {
  /// Falls back to [fallback] when null.
  int orDefault([int fallback = 0]) => this == null ? fallback : this!;

  DateTime? toDateTime() =>
      this == null ? null : DateTime.fromMillisecondsSinceEpoch(this!);
}
