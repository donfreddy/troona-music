import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/history/domain/entities/listening_recap.dart';
import 'package:troona/features/history/presentation/utils/recap_format.dart';
import 'package:troona/features/history/presentation/widgets/listening_calendar.dart';
import 'package:troona/features/history/presentation/widgets/listening_moments_grid.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

/// A recap as a story, 9:16, to share as an image: [size] logical pixels
/// captured at [pixelRatio], 1080 x 1920.
///
/// Its own fixed format: the phone's font size and motion settings do not
/// apply, the image must look the same for everyone it is sent to.
class RecapStory extends StatelessWidget {
  final ListeningRecap recap;
  final int today;

  const RecapStory({super.key, required this.recap, required this.today});

  static const size = Size(360, 640);
  static const pixelRatio = 3.0;

  /// "My week in music"; a finished month is its Replay, named like the
  /// playlist: "Replay October 2026".
  static String titleOf(BuildContext context, ListeningRecap recap, int today) {
    final l10n = context.l10n;
    return switch (recap.period) {
      RecapPeriod.week => l10n.recapStoryWeek,
      RecapPeriod.month when recap.lastDay < today => l10n.replayName(
        DateFormat.yMMMM(
          Localizations.localeOf(context).toString(),
        ).format(recap.start),
      ),
      RecapPeriod.month => l10n.recapStoryMonth,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final top = recap.topTracks.firstOrNull;
    final rest = recap.topTracks.skip(1).take(4).toList();
    final timed = recap.listened > Duration.zero;
    final peak = ListeningMomentsGrid.peakOf(context, recap.moments);
    final dates = switch (recap.period) {
      RecapPeriod.week => formatRecapRange(context, recap, today: today),
      RecapPeriod.month => formatMonth(context, recap.start),
    };

    final content = SizedBox(
      width: size.width - 48,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(AppIcons.listen, color: colors.accent, size: 16),
              const SizedBox(width: 6),
              Text(
                'TROONA',
                style: TextStyle(
                  color: colors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  dates,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.labelSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            titleOf(context, recap, today),
            style: TextStyle(
              color: colors.labelPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -.6,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            timed
                ? formatListened(context, recap.listened)
                : l10n.recapPlays(recap.plays),
            style: TextStyle(
              color: colors.labelPrimary,
              fontSize: 54,
              fontWeight: FontWeight.w300,
              letterSpacing: -1.5,
              height: 1.05,
            ),
          ),
          Text(
            [
              if (timed) l10n.recapListened,
              if (timed) l10n.recapPlays(recap.plays),
              l10n.recapActiveDays(recap.activeDays),
            ].join(' • '),
            style: TextStyle(color: colors.labelSecondary, fontSize: 14),
          ),
          if (top != null) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .5),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ArtworkImage(
                      top.track.artworkPath,
                      width: 104,
                      height: 104,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.recapTopSong.toUpperCase(),
                        style: TextStyle(
                          color: colors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        top.track.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.labelPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      Text(
                        context.artistName(top.track.artist),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.labelSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        l10n.recapPlays(top.plays),
                        style: TextStyle(
                          color: colors.labelTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final (i, ranked) in rest.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        '${i + 2}',
                        style: TextStyle(
                          color: colors.labelTertiary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: ranked.track.title,
                              style: TextStyle(
                                color: colors.labelPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '  ${context.artistName(ranked.track.artist)}',
                              style: TextStyle(color: colors.labelSecondary),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 22),
          Center(
            child: SizedBox(
              width: recap.period == RecapPeriod.week ? size.width - 48 : 236,
              child: ListeningCalendar(
                firstDay: recap.firstDay,
                lastDay: recap.lastDay,
                dayPlays: recap.dayPlays,
                today: today,
              ),
            ),
          ),
          if (peak != null) ...[
            const SizedBox(height: 16),
            Text(
              peak,
              style: TextStyle(
                color: colors.labelPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.noScaling,
        disableAnimations: true,
        // Covers decoded for the image's pixels, not the phone's.
        devicePixelRatio: pixelRatio,
      ),
      child: SizedBox.fromSize(
        size: size,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Colors.black),
              if (top?.track.artworkPath case final path?) _Glow(path: path),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(.9, 1.1),
                    radius: 1.1,
                    colors: [
                      colors.accent.withValues(alpha: .28),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topLeft,
                  child: content,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The top song's cover as a wash of colour over the top of the story,
/// decoded a few pixels wide and stretched: a blur with no filter.
class _Glow extends StatelessWidget {
  final String path;
  const _Glow({required this.path});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: .75,
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: ArtworkImage(
              path,
              width: 8,
              height: 8,
              errorBuilder: (_, _, _) => const SizedBox.square(dimension: 8),
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x66000000), Color(0xCC000000), Colors.black],
              stops: [0, .45, .8],
            ),
          ),
        ),
      ],
    );
  }
}
