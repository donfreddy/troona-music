import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/shared/widgets/entrance_fader.dart';

/// A 2×2 grid of recently played tracks (Spotify-style compact cards).
///
/// Each card is tappable and launches playback of the selected track
/// within the recently-played context queue.
class RecentlyPlayedGrid extends StatelessWidget {
  final List<Track> tracks;

  const RecentlyPlayedGrid({super.key, required this.tracks});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          if (tracks.length >= 2)
            Row(
              children: [
                Expanded(
                  child: EntranceFader.staggered(
                    index: 0,
                    slideY: 0.03,
                    child: _RecentCard(
                      track: tracks[0],
                      onTap: () => _play(context, 0),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: EntranceFader.staggered(
                    index: 1,
                    slideY: 0.03,
                    child: _RecentCard(
                      track: tracks[1],
                      onTap: () => _play(context, 1),
                    ),
                  ),
                ),
              ],
            ),
          if (tracks.length >= 4) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: EntranceFader.staggered(
                    index: 2,
                    slideY: 0.03,
                    child: _RecentCard(
                      track: tracks[2],
                      onTap: () => _play(context, 2),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: EntranceFader.staggered(
                    index: 3,
                    slideY: 0.03,
                    child: _RecentCard(
                      track: tracks[3],
                      onTap: () => _play(context, 3),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _play(BuildContext context, int index) {
    context.read<PlayerBloc>().add(
      PlayTrackRequested(
        tracks[index],
        contextQueue: tracks,
        contextIndex: index,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _RecentCard extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;

  const _RecentCard({required this.track, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final glass = GlassTheme.card(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: glass.fill,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: glass.border, width: glass.borderWidth),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Artwork
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox.square(
                  dimension: 38,
                  child: ArtworkImage(track.artworkPath, width: 38, height: 38),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: TextStyle(
                        color: context.colors.labelPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      track.artist,
                      style: TextStyle(
                        color: context.colors.labelSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
