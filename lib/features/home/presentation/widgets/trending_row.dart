import 'package:flutter/material.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/widgets/track_row_artwork.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';

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
    final (isActive, _) = TrackRowArtwork.statusOf(context, track.id);

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
            TrackRowArtwork(track: track, size: 50),

            const SizedBox(width: AppSpacing.md),

            // Info track
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: TextStyle(
                      color: isActive ? context.colors.accent : Colors.white,
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.artistName(track.artist),
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
