import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

import 'package:troona/core/theme/semantic/app_colors.dart';

class ArtistCard extends StatelessWidget {
  final Artist artist;
  final double? size;

  const ArtistCard({super.key, required this.artist, this.size});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final cardContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: AspectRatio(
            aspectRatio: 1.0,
            child: artist.artworkPath != null && artist.artworkPath!.isNotEmpty
                ? ArtworkImage(artist.artworkPath!)
                : Container(
                    color: Colors.white.withValues(alpha: .08),
                    child: const Icon(
                      LucideIcons.micVocal,
                      color: Colors.white30,
                      size: 48,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          artist.name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        if (artist.trackCount > 0)
          Text(
            '${artist.trackCount} ${artist.trackCount > 1 ? 'titres' : 'titre'}',
            style: TextStyle(fontSize: 11, color: colors.labelSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
      ],
    );

    return GestureDetector(
      onTap: () => context.pushArtist(artist.id),
      child: size != null
          ? SizedBox(width: size, child: cardContent)
          : cardContent,
    );
  }
}
