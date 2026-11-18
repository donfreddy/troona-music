import 'package:flutter/material.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/presentation/widgets/album_actions.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/album_cover_hero.dart';
import 'package:troona/features/player/presentation/widgets/playing_badge.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

/// An album as a row: its cover, name and the line [AlbumCard] gives it.
/// For a section of one or two albums, where a carousel would leave a lone
/// card and an empty row beside it. Tap and long press as on the card.
class AlbumRow extends StatelessWidget {
  final Album album;
  final bool showArtist;
  final bool markSingles;

  const AlbumRow({
    super.key,
    required this.album,
    this.showArtist = true,
    this.markSingles = false,
  });

  static const double cover = 56;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      // The page paints its own background: without a Material here the
      // ink would be drawn under it, out of sight.
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => context.pushAlbum(album.id),
          onLongPress: () => showAlbumActions(context, album),
          // Haptics are the app's (AppHaptics): the menu ticks as it opens, a
          // played song ticks in the player. The system's long-press buzz would
          // be a second one.
          enableFeedback: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: cover,
                  child: Stack(
                    children: [
                      AlbumCoverHero(
                        albumId: album.id,
                        artworkPath: album.artworkPath,
                        radius: AppSpacing.radiusSm,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                          child: ArtworkImage(
                            album.artworkPath,
                            width: cover,
                            height: cover,
                            placeholder: AppIcons.album,
                          ),
                        ),
                      ),
                      // Outside the hero: the cover flies alone.
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: PlayingBadge(
                          matches: (current) =>
                              '${current.albumId}' == album.id,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.labelPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AlbumCard.subtitleOf(
                          context,
                          album,
                          showArtist: showArtist,
                          markSingles: markSingles,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.labelSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
