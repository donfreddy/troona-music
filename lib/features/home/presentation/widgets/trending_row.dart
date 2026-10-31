import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

class TrendingRow extends StatelessWidget {
  final Track track;
  final int rank;
  final VoidCallback onTap;

  const TrendingRow({
    super.key,
    required this.track,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Whether this track is the one playing
    final isActive = context.select<PlayerBloc, bool>(
      (b) =>
          b.state is PlayerActive &&
          (b.state as PlayerActive).currentTrack.id == track.id,
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Artwork, or the visualizer when active
            SizedBox.square(
              dimension: 50,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: track.artworkPath != null
                        ? ArtworkImage(
                            track.artworkPath!,
                            width: 50,
                            height: 50,
                          )
                        : Container(
                            color: Colors.white.withValues(alpha: .08),
                            child: const Icon(
                              AppIcons.track,
                              color: Colors.white30,
                            ),
                          ),
                  ),
                  // Now playing overlay
                  if (isActive)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          AppIcons.nowPlaying,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Info track
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white,
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Text(
              Duration(milliseconds: track.durationMs).toMMSS(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: .4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
