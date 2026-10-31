import 'package:flutter/material.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/core/extensions/context_ext.dart';

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
            child: ArtworkImage(album.artworkPath, placeholder: AppIcons.album),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                album.name,
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
                album.trackCount > 0
                    ? context.l10n.albumByArtist(
                        album.artist,
                        context.l10n.songCount(album.trackCount),
                      )
                    : album.artist,
                style: TextStyle(
                  color: context.colors.labelSecondary,
                  fontSize: 12,
                  height: 1.2,
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
      onTap: () => context.pushAlbum(album.id),
      child: size != null
          ? SizedBox(width: size, child: cardContent)
          : cardContent,
    );
  }
}
