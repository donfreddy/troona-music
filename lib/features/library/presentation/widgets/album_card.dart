import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/album.dart';

class AlbumCard extends StatelessWidget {
  final Album album;

  const AlbumCard({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.goNamed('album_detail', pathParameters: {'id': album.id}),
      child: SizedBox(
        width: 160,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: SizedBox.square(
                dimension: 160,
                child: album.artworkPath != null
                    ? Image.file(File(album.artworkPath!), fit: BoxFit.cover)
                    : Container(
                        color: Colors.white.withValues(alpha: .08),
                        child: Icon(
                          LucideIcons.disc,
                          color: Colors.white30,
                          size: 64,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    album.artist,
                    style: TextStyle(
                      color: context.colors.labelSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
