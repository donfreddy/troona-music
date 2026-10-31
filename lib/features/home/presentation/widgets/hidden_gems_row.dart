import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/shared/widgets/entrance_fader.dart';

/// Horizontal scrollable row of "Hidden Gems": liked tracks the user
/// hasn't listened to recently.
///
/// Visual accent: a subtle gem icon overlay and softer card tint.
class HiddenGemsRow extends StatelessWidget {
  final List<Track> tracks;

  const HiddenGemsRow({super.key, required this.tracks});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: tracks.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) => EntranceFader.staggered(
          index: i,
          slideY: 0.04,
          key: ValueKey('gem-${tracks[i].id}'),
          child: _GemCard(track: tracks[i]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _GemCard extends StatelessWidget {
  final Track track;

  const _GemCard({required this.track});

  @override
  Widget build(BuildContext context) {
    final glass = GlassTheme.card(context);

    return GestureDetector(
      onTap: () => context.read<PlayerBloc>().add(PlayTrackRequested(track)),
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork with gem indicator
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: SizedBox.square(
                    dimension: 130,
                    child: track.artworkPath != null
                        ? ArtworkImage(
                            track.artworkPath!,
                            width: 130,
                            height: 130,
                          )
                        : Container(
                            color: Colors.white.withValues(alpha: .08),
                            child: const Icon(
                              AppIcons.track,
                              color: Colors.white30,
                              size: 48,
                            ),
                          ),
                  ),
                ),
                // Heart + gem overlay
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
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
                          AppIcons.like,
                          size: 10,
                          color: context.colors.accent,
                        ),
                        const SizedBox(width: 3),
                        Text('💎', style: const TextStyle(fontSize: 10)),
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
