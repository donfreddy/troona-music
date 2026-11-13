import 'package:flutter/material.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/presentation/widgets/album_cover_hero.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/shared/widgets/meta_line.dart';
import 'package:troona/core/extensions/context_ext.dart';

class AlbumCard extends StatelessWidget {
  final Album album;
  final double? size;

  /// False where the page already names the artist (their page, More by):
  /// the line under the name gives the year instead.
  final bool showArtist;

  /// With [showArtist] off, adds Single after a single's year: for a row
  /// that mixes singles and albums (More by), not under a Singles title.
  final bool markSingles;

  const AlbumCard({
    super.key,
    required this.album,
    this.size,
    this.showArtist = true,
    this.markSingles = false,
  });

  String _subtitle(BuildContext context) {
    final l10n = context.l10n;
    final kind = album.isSingle
        ? l10n.albumSingle
        : l10n.songCount(album.trackCount);
    if (!showArtist) {
      return switch (album.year) {
        final year? => MetaLine.join([
          '$year',
          if (markSingles && album.isSingle) l10n.albumSingle,
        ])!,
        null => kind,
      };
    }
    final artist = context.artistName(album.artist);
    return album.trackCount > 0 ? l10n.albumByArtist(artist, kind) : artist;
  }

  @override
  Widget build(BuildContext context) {
    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AlbumCoverHero(
          albumId: album.id,
          artworkPath: album.artworkPath,
          radius: AppSpacing.radiusMd,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: ArtworkImage(
                album.artworkPath,
                placeholder: AppIcons.album,
              ),
            ),
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
                _subtitle(context),
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
