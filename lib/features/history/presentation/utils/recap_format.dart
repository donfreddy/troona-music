import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/features/history/domain/entities/weekly_recap.dart';

/// "2 h 40 min", or "40 min" under an hour; a few seconds read as 1 min.
String formatListened(BuildContext context, Duration listened) {
  final l10n = context.l10n;
  final hours = listened.inHours;
  final minutes = listened.inMinutes % 60;
  if (hours > 0) return l10n.recapHoursMinutes(hours, minutes);
  return l10n.recapMinutes(minutes == 0 ? 1 : minutes);
}

/// "Oct 19 to 25" style range of the recap's week, in the app's locale.
String formatRecapRange(BuildContext context, WeeklyRecap recap) {
  final locale = Localizations.localeOf(context).toString();
  final day = DateFormat.MMMd(locale);
  return context.l10n.recapRange(
    day.format(recap.weekStart),
    day.format(recap.weekEnd),
  );
}
