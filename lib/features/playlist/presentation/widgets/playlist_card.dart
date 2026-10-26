import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/playlist/presentation/widgets/playlist_mosaic.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

/// Premium Playlist Card used in Grid layouts and Home carousels.
class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final double? size;

  const PlaylistCard({super.key, required this.playlist, this.size});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLikes = playlist.id == IsarLibraryDataSource.likesPlaylistId;
    final count = playlist.trackIds.length;
    final countLabel = count == 1 ? '1 titre' : '$count titres';

    final coverWidget = AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLikes
                ? const Color(0xFFFA2D48).withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isLikes
                  ? const Color(0xFFFA2D48).withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isLikes)
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF9E1427),
                        Color(0xFFFA2D48),
                        Color(0xFF45060F),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.heart,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                )
              else if (playlist.artworkPath != null &&
                  playlist.artworkPath!.isNotEmpty)
                ArtworkImage(playlist.artworkPath!)
              else if (playlist.trackIds.isNotEmpty)
                PlaylistMosaic(trackIds: playlist.trackIds, size: size ?? 150)
              else
                Container(
                  color: colors.glassFill,
                  child: Center(
                    child: Icon(
                      LucideIcons.listMusic,
                      color: colors.labelTertiary,
                      size: 36,
                    ),
                  ),
                ),

              // Bottom pill with track count
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    countLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        coverWidget,
        const SizedBox(height: 8),

        // Title
        Text(
          isLikes ? 'Titres likés' : playlist.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),

        // Subtitle
        Text(
          isLikes ? 'Coups de cœur' : 'Playlist',
          style: TextStyle(
            color: isLikes
                ? const Color(0xFFFF5E79)
                : colors.labelSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    return GestureDetector(
      onTap: () => context.pushPlaylist(playlist.id),
      child: size != null
          ? SizedBox(width: size, child: cardContent)
          : cardContent,
    );
  }
}
