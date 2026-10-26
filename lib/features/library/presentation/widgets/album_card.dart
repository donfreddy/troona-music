import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

class AlbumCard extends StatelessWidget {
  final Album album;
  final double? size;

  const AlbumCard({super.key, required this.album, this.size});

  @override
  Widget build(BuildContext context) {
    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: AspectRatio(
            aspectRatio: 1.0,
            child: album.artworkPath != null && album.artworkPath!.isNotEmpty
                ? ArtworkImage(album.artworkPath!)
                : Container(
                    color: Colors.white.withValues(alpha: .08),
                    child: const Icon(
                      LucideIcons.disc,
                      color: Colors.white30,
                      size: 48,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                album.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                album.artist,
                style: TextStyle(
                  color: context.colors.labelSecondary,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (album.trackCount > 0)
                Text(
                  '${album.trackCount} ${album.trackCount > 1 ? 'titres' : 'titre'}',
                  style: TextStyle(
                    color: context.colors.labelTertiary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: () => context.pushNamed(
        AppRoute.albumDetail,
        pathParameters: {'id': album.id},
      ),
      child: size != null
          ? SizedBox(width: size, child: cardContent)
          : cardContent,
    );
  }
}
