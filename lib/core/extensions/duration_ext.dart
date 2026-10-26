import 'package:troona/l10n/app_localizations.dart';

extension DurationExt on Duration {
  /// `3:04` for minutes; `1:02:03` when hours > 0.
  String toMMSS() {
    final h = inHours;
    final m = inMinutes.remainder(60);
    final s = inSeconds.remainder(60);

    final mm = m.toString().padLeft(h > 0 ? 2 : 1, '0');
    final ss = s.toString().padLeft(2, '0');

    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  /// Human friendly label: `3 min`, `1 hr 2 min` (localized).
  String toHumanReadable(AppLocalizations l10n) {
    final h = inHours;
    final m = inMinutes.remainder(60);
    if (h == 0) return l10n.durationMinutes(m);
    return m == 0 ? l10n.durationHours(h) : l10n.durationHoursMinutes(h, m);
  }

  /// Progress ratio clamped to [0.0, 1.0].
  double progressOf(Duration total) {
    if (total <= Duration.zero) return 0.0;
    return (inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
  }
}
