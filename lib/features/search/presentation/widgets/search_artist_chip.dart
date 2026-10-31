import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
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
                child: ArtworkImage(
                  artist.artworkPath,
                  placeholder: AppIcons.artist,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.artistName(artist.name),
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
