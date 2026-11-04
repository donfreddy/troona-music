import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/history/domain/services/listening_moments.dart';
import 'package:troona/features/history/domain/services/play_intensity.dart';
import 'package:troona/features/history/presentation/widgets/heat_cell.dart';

/// "When you listen": the plays of a span by weekday and part of the day,
/// with the moment that stands out said in words.
///
/// The steps are relative to the busiest cell: here the shape of the week
/// matters, not its volume, which the calendar already shows.
class ListeningMomentsGrid extends StatelessWidget {
  final ListeningMoments moments;

  /// Restarts the cascade when the span changes.
  final Object spanKey;

  const ListeningMomentsGrid({
    super.key,
    required this.moments,
    required this.spanKey,
  });

  /// "Friday", in the app's language; 1 is Monday.
  static String weekdayName(BuildContext context, int weekday) {
    final locale = Localizations.localeOf(context).toString();
    // 2026-10-19 is a Monday.
    return DateFormat.EEEE(locale).format(DateTime(2026, 10, 18 + weekday));
  }

  static String partName(BuildContext context, DayPart part) {
    final l10n = context.l10n;
    return switch (part) {
      DayPart.morning => l10n.recapMorning,
      DayPart.afternoon => l10n.recapAfternoon,
      DayPart.evening => l10n.recapEvening,
      DayPart.night => l10n.recapNight,
    };
  }

  static IconData _iconOf(DayPart part) => switch (part) {
    DayPart.morning => AppIcons.morning,
    DayPart.afternoon => AppIcons.afternoon,
    DayPart.evening => AppIcons.evening,
    DayPart.night => AppIcons.night,
  };

  /// "Peak: Friday evening"; a night is the one after its weekday:
  /// "Peak: Friday night", the night from Friday to Saturday.
  static String? peakOf(BuildContext context, ListeningMoments moments) {
    final peak = moments.peak;
    if (peak == null) return null;
    final (weekday, part) = peak;
    final l10n = context.l10n;
    if (part == DayPart.night) {
      return l10n.recapPeakNight(
        weekdayName(context, weekday),
        weekdayName(context, weekday % 7 + 1),
      );
    }
    return l10n.recapPeak(
      weekdayName(context, weekday),
      partName(context, part).toLowerCase(),
    );
  }

  /// The row headers are icons alone, in a fixed column: names would take
  /// the room of the squares at large font sizes. Each square says its
  /// part to screen readers, and a tap on an icon names it.
  static const _headerWidth = 28.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    if (moments.isEmpty) {
      return Text(
        l10n.recapMomentsEmpty,
        style: TextStyle(color: colors.labelSecondary, fontSize: 15),
      );
    }
    final locale = Localizations.localeOf(context).toString();
    final initials = [
      for (var i = 0; i < 7; i++)
        DateFormat.EEEEE(locale).format(DateTime(2026, 10, 19 + i)),
    ];
    final weekdays = [for (var w = 1; w <= 7; w++) weekdayName(context, w)];
    final max = moments.maxRate;
    final peak = peakOf(context, moments);
    const gap = 2.5;
    // Built once: the cascade rebuilds its wrappers on every frame.
    final cells = [
      for (final part in DayPart.values)
        [
          for (var weekday = 1; weekday <= 7; weekday++)
            HeatCell(
              level: PlayIntensity.relativeLevelOf(
                moments.rateAt(weekday, part),
                max,
              ),
              semanticLabel:
                  '${weekdays[weekday - 1]}, ${partName(context, part)}, '
                  '${l10n.recapPlays(moments.playsAt(weekday, part))}',
            ),
        ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (peak != null) ...[
          Text(
            peak,
            style: TextStyle(
              color: colors.labelPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        HeatCascade(
          key: ValueKey(spanKey),
          steps: DayPart.values.length + 6,
          builder: (context, reveal) => Table(
            columnWidths: const {0: FixedColumnWidth(_headerWidth)},
            defaultColumnWidth: const FlexColumnWidth(),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                children: [
                  const SizedBox.shrink(),
                  for (final initial in initials)
                    ExcludeSemantics(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
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
                    ),
                ],
              ),
              for (final (row, part) in DayPart.values.indexed)
                TableRow(
                  children: [
                    Tooltip(
                      message: partName(context, part),
                      triggerMode: TooltipTriggerMode.tap,
                      excludeFromSemantics: true,
                      child: ExcludeSemantics(
                        child: Icon(
                          _iconOf(part),
                          size: 18,
                          color: colors.labelSecondary,
                        ),
                      ),
                    ),
                    for (var weekday = 1; weekday <= 7; weekday++)
                      Padding(
                        padding: const EdgeInsets.all(gap),
                        child: reveal(
                          row + weekday - 1,
                          cells[row][weekday - 1],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
