import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';

/// One month as dots, Monday first: filled on days with at least one
/// counted play. No count and no streak: a quiet day is just an empty dot.
class ListeningCalendar extends StatelessWidget {
  final DateTime month;

  /// Days of [month] (1 to 31) with music.
  final Set<int> activeDays;

  final DateTime today;

  const ListeningCalendar({
    super.key,
    required this.month,
    required this.activeDays,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = DateTime(month.year, month.month).weekday - 1;
    final weeks = ((leading + daysInMonth) / 7).ceil();
    // 2026-10-19 is a Monday.
    final initials = [
      for (var i = 0; i < 7; i++)
        DateFormat.EEEEE(locale).format(DateTime(2026, 10, 19 + i)),
    ];
    final title = DateFormat.yMMMM(locale).format(month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title[0].toUpperCase() + title.substring(1),
          style: TextStyle(
            color: colors.labelPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ExcludeSemantics(
          child: Row(
            children: [
              for (final initial in initials)
                Expanded(
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: colors.labelTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var w = 0; w < weeks; w++)
          Row(
            children: [
              for (var d = 0; d < 7; d++)
                Expanded(child: _cell(context, w * 7 + d - leading + 1)),
            ],
          ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.recapCalendarCaption,
          style: TextStyle(color: colors.labelSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _cell(BuildContext context, int day) {
    if (day < 1 || day > DateTime(month.year, month.month + 1, 0).day) {
      return const SizedBox(height: 36);
    }
    final colors = context.colors;
    final date = DateTime(month.year, month.month, day);
    final isToday = date == DateTime(today.year, today.month, today.day);
    final isFuture = date.isAfter(today);
    final active = activeDays.contains(day);
    final locale = Localizations.localeOf(context).toString();
    final label = DateFormat.MMMMd(locale).format(date);

    return Semantics(
      label: active
          ? context.l10n.recapCalendarDay(label)
          : context.l10n.recapCalendarQuietDay(label),
      excludeSemantics: true,
      child: SizedBox(
        height: 36,
        child: Center(
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? colors.accent : null,
              border: active
                  ? null
                  : Border.all(
                      color: colors.labelTertiary.withValues(
                        alpha: isFuture ? .3 : 1,
                      ),
                      width: 1,
                    ),
              boxShadow: isToday
                  ? [
                      BoxShadow(
                        color: colors.accent.withValues(alpha: .5),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
