import 'dart:async';

import 'package:flutter/material.dart';
import 'package:troona/features/player/presentation/widgets/playing_badge.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/presentation/widgets/artist_photo_hero.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/core/extensions/context_ext.dart';

class ArtistCard extends StatefulWidget {
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
  State<ArtistCard> createState() => _ArtistCardState();
}

class _ArtistCardState extends State<ArtistCard> {
  StreamSubscription<String>? _artworkSub;
  String? _effectiveArtwork;

  /// Their downloaded photo, when the card shows it: it flies to their
  /// page. A cover does not.
  String? _photo;

  @override
  void initState() {
    super.initState();
    _resolveArtwork();
    _artworkSub = getIt<MetadataRepository>().onArtistArtworkUpdated.listen((
      updatedId,
    ) {
      final mine =
          updatedId == widget.artist.id ||
          updatedId == MetadataRepository.allArtists;
      if (mine && mounted) {
        _resolveArtwork();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ArtistCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artist.id != widget.artist.id) {
      _resolveArtwork();
    }
  }

  void _resolveArtwork() {
    final cached = getIt<MetadataRepository>().getCachedArtistArtworkPath(
      widget.artist.id,
    );
    final next = cached ?? widget.artist.artworkPath;
    final photo = cached != null && cached.isNotEmpty ? cached : null;
    if (next != _effectiveArtwork || photo != _photo) {
      setState(() {
        _effectiveArtwork = next;
        _photo = photo;
      });
    }
  }

  @override
  void dispose() {
    _artworkSub?.cancel();
    super.dispose();
  }

  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  Widget _withPhotoHero(Widget circle) => switch (_photo) {
    final photo? => ArtistPhotoHero(
      artistId: widget.artist.id,
      photo: photo,
      round: true,
      child: circle,
    ),
    null => circle,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final artwork = _effectiveArtwork;

    final cardContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            _withPhotoHero(
              ClipOval(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: artwork != null && artwork.isNotEmpty
                      ? ArtworkImage(artwork)
                      : Container(
                          color: colors.glassFill,
                          alignment: Alignment.center,
                          // Sized from the circle, not the phone's font size: a
                          // drawing, which the name under it already says.
                          child: LayoutBuilder(
                            builder: (context, box) => Text(
                              _getInitials(widget.artist.name),
                              textScaler: TextScaler.noScaling,
                              style: TextStyle(
                                color: colors.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: box.maxWidth * 0.32,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            // On the circle's edge, low on the right.
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0.78, 0.78),
                child: PlayingBadge(
                  matches: (current) =>
                      current.credits.any((c) => '${c.id}' == widget.artist.id),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          context.artistName(widget.artist.name),
          style: ArtistCard._nameStyle,
          strutStyle: ArtistCard.strutOf(ArtistCard._nameStyle),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        if (widget.artist.trackCount > 0)
          Text(
            context.l10n.songCount(widget.artist.trackCount),
            strutStyle: ArtistCard.strutOf(ArtistCard._countStyle),
            style: ArtistCard._countStyle.copyWith(
              color: colors.labelSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
      ],
    );

    return GestureDetector(
      onTap: () => context.pushArtist(widget.artist.id),
      child: widget.size != null
          ? SizedBox(width: widget.size, child: cardContent)
          : cardContent,
    );
  }
}
