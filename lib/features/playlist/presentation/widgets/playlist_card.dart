import 'package:flutter/material.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/playlist/presentation/widgets/playlist_cover.dart';
import 'package:troona/core/extensions/context_ext.dart';

/// Playlist card for grids and Home carousels.
///
/// Drawn like [AlbumCard]: a flat cover with no border or shadow, so it sits
/// on the glowing background the same way every other cover does.
class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final double? size;
  final VoidCallback? onLongPress;

  const PlaylistCard({
    super.key,
    required this.playlist,
    this.size,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLikes = playlist.id == Playlist.likesId;

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: AspectRatio(
            aspectRatio: 1.0,
            // Grid cells are about 180 wide on a phone.
            child: PlaylistCover(playlist: playlist, size: size ?? 180),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isLikes ? context.l10n.likedSongs : playlist.name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          context.l10n.songCount(playlist.trackIds.length),
          style: TextStyle(
            color: colors.labelSecondary,
            fontSize: 12,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    return GestureDetector(
      onTap: () => context.pushPlaylist(playlist.id),
      onLongPress: onLongPress,
      child: size != null
          ? SizedBox(width: size, child: cardContent)
          : cardContent,
    );
  }
}
