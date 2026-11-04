import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/history/domain/services/play_intensity.dart';
import 'package:troona/features/history/presentation/widgets/heat_cell.dart';

/// The days of a week or a month as squares, Monday first, filled by how
/// much music each day had ([PlayIntensity]). A week is one row; a month,
/// its calendar.
class ListeningCalendar extends StatelessWidget {
  /// The span's first and last day, as `ListeningDay` keys.
  final int firstDay;
  final int lastDay;

  /// Plays per day; a day absent had none.
  final Map<int, int> dayPlays;

  final int today;

  const ListeningCalendar({
    super.key,
    required this.firstDay,
    required this.lastDay,
    required this.dayPlays,
    required this.today,
  });

  static const _gap = 5.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final leading = ListeningDay.weekday(firstDay) - 1;
    final weeks = ((leading + lastDay - firstDay + 1) / 7).ceil();
    // 2026-10-19 is a Monday.
    final initials = [
      for (var i = 0; i < 7; i++)
        DateFormat.EEEEE(locale).format(DateTime(2026, 10, 19 + i)),
    ];

    final dayFormat = DateFormat.MMMMEEEEd(locale);
    final cells = [
      for (var i = 0; i < weeks * 7; i++)
        _cell(context, firstDay + i - leading, dayFormat),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        HeatCascade(
          key: ValueKey(firstDay),
          steps: weeks + 6,
          // [cells] are built once: the cascade rebuilds on every frame.
          builder: (context, reveal) => Column(
            children: [
              for (var w = 0; w < weeks; w++)
                Padding(
                  padding: EdgeInsets.only(top: w == 0 ? 0 : _gap),
                  child: Row(
                    children: [
                      for (var d = 0; d < 7; d++) ...[
                        if (d > 0) const SizedBox(width: _gap),
                        Expanded(child: reveal(w + d, cells[w * 7 + d])),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const HeatLegend(),
      ],
    );
  }

  Widget _cell(BuildContext context, int day, DateFormat dayFormat) {
    if (day < firstDay || day > lastDay) {
      return const AspectRatio(aspectRatio: 1);
    }
    final date = ListeningDay.date(day);
    final plays = dayPlays[day] ?? 0;
    return HeatCell(
      level: PlayIntensity.levelOf(plays),
      text: '${date.day}',
      marked: day == today,
      future: day > today,
      semanticLabel: context.l10n.recapDayPlays(dayFormat.format(date), plays),
    );
  }
}
