import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/playlist/presentation/widgets/playlist_mosaic.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final double size;

  const PlaylistCard({super.key, required this.playlist, this.size = 160});

  @override
  Widget build(BuildContext context) {
    final isLikes = playlist.id == IsarLibraryDataSource.likesPlaylistId;

    return GestureDetector(
      onTap: () => context.goNamed(
        AppRoute.playlistDetail,
        pathParameters: {'id': playlist.id},
      ),
      child: SizedBox(
        width: size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: SizedBox.square(
                dimension: size,
                child: isLikes
                    ? Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF450AF5),
                              Color(0xFF8E8EE5),
                            ],
                          ),
                        ),
                        child: Icon(
                          LucideIcons.heart,
                          color: Colors.white,
                          size: size * 0.38,
                        ),
                      )
                    : playlist.artworkPath != null
                        ? ArtworkImage(playlist.artworkPath!)
                        : playlist.trackIds.isNotEmpty
                            ? PlaylistMosaic(trackIds: playlist.trackIds)
                            : Container(
                                color: Colors.white10,
                                child: const Icon(
                                  LucideIcons.listMusic,
                                  color: Colors.white30,
                                  size: 40,
                                ),
                              ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Titre
            Text(
              isLikes ? 'Titres likés' : playlist.name,
              style: TextStyle(
                color: context.colors.labelPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 2),

            Text(
              '${playlist.trackIds.length} morceaux',
              style: TextStyle(
                color: context.colors.labelSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
