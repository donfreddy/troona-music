import 'package:flutter/material.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/presentation/widgets/album_actions.dart';
import 'package:troona/features/library/presentation/widgets/album_cover_hero.dart';
import 'package:troona/features/player/presentation/widgets/playing_badge.dart';
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

  static const _titleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
  );
  static const _subtitleStyle = TextStyle(fontSize: 12, height: 1.2);

  /// Height of the card below its cover at the phone's font size: a grid
  /// cell is the cover and this, with no room left empty under it.
  /// Each line exactly its font size times its height, whatever fonts
  /// draw it: a name mixing scripts (Latin and CJK) would run taller.
  @visibleForTesting
  static StrutStyle strutOf(TextStyle style) => StrutStyle(
    fontSize: style.fontSize,
    height: style.height,
    forceStrutHeight: true,
  );

  static double textHeight(BuildContext context) {
    final base = DefaultTextStyle.of(context).style;
    final scaler = MediaQuery.textScalerOf(context);
    double line(TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: 'Ag', style: base.merge(style)),
        strutStyle: strutOf(style),
        textScaler: scaler,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final height = painter.height;
      painter.dispose();
      return height;
    }

    return 6 + line(_titleStyle) + 2 + line(_subtitleStyle);
  }

  @override
  Widget build(BuildContext context) {
    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
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
            // Outside the hero: the cover flies alone.
            Positioned(
              right: 6,
              bottom: 6,
              child: PlayingBadge(
                matches: (current) => '${current.albumId}' == album.id,
              ),
            ),
          ],
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
                style: _titleStyle,
                strutStyle: strutOf(_titleStyle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _subtitle(context),
                strutStyle: strutOf(_subtitleStyle),
                style: _subtitleStyle.copyWith(
                  color: context.colors.labelSecondary,
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
      onLongPress: () => showAlbumActions(context, album),
      child: size != null
          ? SizedBox(width: size, child: cardContent)
          : cardContent,
    );
  }
}
