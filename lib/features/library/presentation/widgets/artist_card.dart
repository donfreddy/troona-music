import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/features/library/domain/entities/artist.dart';

class ArtistCard extends StatelessWidget {
  final Artist artist;
  final double size;

  const ArtistCard({super.key, required this.artist, this.size = 160});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.goNamed(
        AppRoute.artistDetail,
        pathParameters: {'id': artist.id},
      ),
      child: SizedBox(
        width: size,
        child: Column(
          children: [
            ClipOval(
              child: SizedBox.square(
                dimension: size,
                child: artist.artworkPath != null
                    ? Image.file(File(artist.artworkPath!), fit: BoxFit.cover)
                    : Container(
                        color: Colors.white.withValues(alpha: .08),
                        child: Icon(
                          LucideIcons.micVocal,
                          color: Colors.white30,
                          size: 64,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              artist.name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
