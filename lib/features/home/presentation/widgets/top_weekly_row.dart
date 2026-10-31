import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/home/domain/entities/track_play_count.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/shared/widgets/entrance_fader.dart';

/// Horizontal scrollable row of "Your Top This Week" cards.
///
/// Each card shows the track artwork, rank badge, title, artist,
/// and a play count indicator. Tapping plays the track.
class TopWeeklyRow extends StatelessWidget {
  final List<TrackPlayCount> items;

  const TopWeeklyRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) => EntranceFader.staggered(
          index: i,
          slideY: 0.04,
          key: ValueKey('top-weekly-${items[i].track.id}'),
          child: _TopCard(item: items[i], rank: i + 1),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TopCard extends StatelessWidget {
  final TrackPlayCount item;
  final int rank;

  const _TopCard({required this.item, required this.rank});

  @override
  Widget build(BuildContext context) {
    final track = item.track;
    final glass = GlassTheme.card(context);

    return GestureDetector(
      onTap: () => context.read<PlayerBloc>().add(PlayTrackRequested(track)),
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork with rank badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: SizedBox.square(
                    dimension: 130,
                    child: ArtworkImage(
                      track.artworkPath,
                      width: 130,
                      height: 130,
                    ),
                  ),
                ),
                // Rank badge
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: context.colors.accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        color: context.colors.accentForeground,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                // Play count badge
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: glass.fill,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                      border: Border.all(
                        color: glass.border,
                        width: glass.borderWidth,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppIcons.play,
                          size: 10,
                          color: context.colors.labelSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${item.playCount}',
                          style: TextStyle(
                            color: context.colors.labelSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Title
            Text(
              track.title,
              style: TextStyle(
                color: context.colors.labelPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              track.artist,
              style: TextStyle(
                color: context.colors.labelSecondary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
