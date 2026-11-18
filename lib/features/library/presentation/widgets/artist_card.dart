import 'package:flutter/material.dart';
import 'package:troona/features/player/presentation/widgets/playing_badge.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/presentation/widgets/artist_avatar.dart';
import 'package:troona/core/extensions/context_ext.dart';

class ArtistCard extends StatelessWidget {
  final Artist artist;
  final double? size;

  const ArtistCard({super.key, required this.artist, this.size});

  // Lines of a set height, whatever font draws the name (CJK, Thai and
  // Arabic fonts run taller): the grid's cells are measured from them.
  static const _nameStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
  );
  static const _countStyle = TextStyle(fontSize: 11, height: 1.2);

  /// Height of the card below its circle at the phone's font size, song
  /// count included: a grid cell is the circle and this.
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

    return 6 + line(_nameStyle) + line(_countStyle);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final cardContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            ArtistAvatar(artist: artist),
            // On the circle's edge, low on the right.
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0.78, 0.78),
                child: PlayingBadge(
                  matches: (current) =>
                      current.credits.any((c) => '${c.id}' == artist.id),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          context.artistName(artist.name),
          style: _nameStyle,
          strutStyle: strutOf(_nameStyle),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        if (artist.trackCount > 0)
          Text(
            context.l10n.songCount(artist.trackCount),
            strutStyle: strutOf(_countStyle),
            style: _countStyle.copyWith(color: colors.labelSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
      ],
    );

    return GestureDetector(
      onTap: () => context.pushArtist(artist.id),
      child: size != null
          ? SizedBox(width: size, child: cardContent)
          : cardContent,
    );
  }
}
