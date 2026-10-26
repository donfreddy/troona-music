import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/history/domain/entities/weekly_recap.dart';
import 'package:troona/features/history/presentation/utils/recap_format.dart';

/// Home card for last week: listening time and top artist. One card, no
/// badge; tapping it opens the recap page.
class WeeklyRecapCard extends StatelessWidget {
  final WeeklyRecap recap;
  final VoidCallback onTap;

  const WeeklyRecapCard({super.key, required this.recap, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final glass = GlassTheme.card(context);
    final l10n = context.l10n;

    // Weeks rebuilt from the old history have plays but no listening time.
    final (main, mainCaption) = recap.listened > Duration.zero
        ? (formatListened(context, recap.listened), l10n.recapListened)
        : (l10n.recapPlays(recap.plays), null);
    final artist = recap.topArtistTrack?.artist;
    final (second, secondCaption) = artist != null
        ? (artist, l10n.recapTopArtist)
        : (recap.topTrack?.title, l10n.recapTopSong);

    return Semantics(
      button: true,
      hint: l10n.recapOpen,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: glass.fill,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: glass.border, width: glass.borderWidth),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.calendarHeart,
                    color: colors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.recapTitle,
                          style: TextStyle(
                            color: colors.labelPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          formatRecapRange(context, recap),
                          style: TextStyle(
                            color: colors.labelSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    color: colors.labelTertiary,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Stat(value: main, caption: mainCaption),
                  ),
                  if (second != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _Stat(value: second, caption: secondCaption),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String? caption;

  const _Stat({required this.value, this.caption});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.labelPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (caption != null)
          Text(
            caption!,
            style: TextStyle(color: colors.labelSecondary, fontSize: 13),
          ),
      ],
    );
  }
}
