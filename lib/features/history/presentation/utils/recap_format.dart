import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/features/history/domain/entities/listening_recap.dart';
import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/history/presentation/cubit/listening_recap_cubit.dart';

/// "2 h 40 min", or "40 min" under an hour; a few seconds read as 1 min.
String formatListened(BuildContext context, Duration listened) {
  final l10n = context.l10n;
  final hours = listened.inHours;
  final minutes = listened.inMinutes % 60;
  if (hours > 0) return l10n.recapHoursMinutes(hours, minutes);
  return l10n.recapMinutes(minutes == 0 ? 1 : minutes);
}

/// "Oct 19 to 25" style range of the recap's week, in the app's locale.
String formatRecapRange(BuildContext context, ListeningRecap recap) {
  final locale = Localizations.localeOf(context).toString();
  final day = DateFormat.MMMd(locale);
  return context.l10n.recapRange(
    day.format(recap.start),
    day.format(recap.end),
  );
}

/// "September 2026", capitalised as a title in every language.
String formatMonth(BuildContext context, DateTime month) {
  final locale = Localizations.localeOf(context).toString();
  final text = DateFormat.yMMMM(locale).format(month);
  return text[0].toUpperCase() + text.substring(1);
}

/// The name of a span: "This week", "Last month", else its dates.
String formatSpanTitle(BuildContext context, ListeningRecapState state) {
  final l10n = context.l10n;
  final (first, last) = state.period.rangeOf(state.firstDay);
  return switch (state.period) {
    RecapPeriod.week when state.isCurrent => l10n.recapThisWeek,
    RecapPeriod.week when state.isPrevious => l10n.recapLastWeek,
    RecapPeriod.month when state.isCurrent => l10n.recapThisMonth,
    RecapPeriod.month when state.isPrevious => l10n.recapLastMonth,
    RecapPeriod.week => _range(context, first, last),
    RecapPeriod.month => formatMonth(context, ListeningDay.date(first)),
  };
}

/// The dates under a span named in words ("This week": "Oct 19 to 25"),
/// null when its title already gives them.
String? formatSpanDates(BuildContext context, ListeningRecapState state) {
  if (!state.isCurrent && !state.isPrevious) return null;
  final (first, last) = state.period.rangeOf(state.firstDay);
  return switch (state.period) {
    RecapPeriod.week => _range(context, first, last),
    RecapPeriod.month => formatMonth(context, ListeningDay.date(first)),
  };
}

String _range(BuildContext context, int first, int last) {
  final locale = Localizations.localeOf(context).toString();
  final day = DateFormat.MMMd(locale);
  return context.l10n.recapRange(
    day.format(ListeningDay.date(first)),
    day.format(ListeningDay.date(last)),
  );
}
