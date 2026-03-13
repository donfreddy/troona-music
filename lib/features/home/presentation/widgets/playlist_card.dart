import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/home/presentation/widgets/playlist_mosaic.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;

  const PlaylistCard({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/playlist/${playlist.id}'),
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork carré avec coin arrondi
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: SizedBox.square(
                dimension: 160,
                child: playlist.artworkPath != null
                    ? Image.file(File(playlist.artworkPath!), fit: BoxFit.cover)
                    // Mosaic 2×2 si pas d'artwork unique
                    : PlaylistMosaic(trackIds: playlist.trackIds),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Titre
            Text(
              playlist.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 2),

            // Sous-titre — nombre de titres
            Text(
              '${playlist.trackIds.length} titres',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
