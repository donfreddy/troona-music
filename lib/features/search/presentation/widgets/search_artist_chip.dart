import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

/// An artist as a round photo over its name, in search suggestions and
/// results. Opens the artist page.
class SearchArtistChip extends StatelessWidget {
  final Artist artist;

  const SearchArtistChip({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: () => context.pushNamed(
        AppRoute.artistDetail,
        pathParameters: {'id': artist.id},
      ),
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            ClipOval(
              child: SizedBox.square(
                dimension: 72,
                child:
                    artist.artworkPath != null && artist.artworkPath!.isNotEmpty
                    ? ArtworkImage(artist.artworkPath!)
                    : Container(
                        color: Colors.white.withValues(alpha: .08),
                        child: const Icon(
                          LucideIcons.micVocal,
                          color: Colors.white30,
                          size: 32,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              artist.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.labelPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
