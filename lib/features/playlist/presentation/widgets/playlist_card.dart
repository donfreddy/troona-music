import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/playlist/presentation/widgets/playlist_mosaic.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final double size;

  const PlaylistCard({super.key, required this.playlist, this.size = 160});

  @override
  Widget build(BuildContext context) {
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
                child: playlist.artworkPath != null
                    ? Image.file(File(playlist.artworkPath!), fit: BoxFit.cover)
                    : PlaylistMosaic(trackIds: playlist.trackIds),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Titre
            Text(
              playlist.name,
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
              '${playlist.trackIds.length} tracks',
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
