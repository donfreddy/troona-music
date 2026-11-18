import 'package:flutter/material.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/presentation/widgets/artist_avatar.dart';

/// An artist as a round photo over its name, in search suggestions and
/// results: their downloaded photo, else their cover. Opens the artist
/// page in the Search tab.
class SearchArtistChip extends StatelessWidget {
  final Artist artist;

  const SearchArtistChip({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      // In the Search tab: the Library's named route would switch tabs.
      onTap: () => context.pushArtist(artist.id),
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            SizedBox.square(dimension: 72, child: ArtistAvatar(artist: artist)),
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
