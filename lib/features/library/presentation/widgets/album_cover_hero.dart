import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

/// An album's cover that flies from its card to the album page, and back:
/// the page opens where the cover was tapped.
///
/// In flight it is the cover alone, its corners going from [radius] here to
/// the other end's: the page's own cover reads blocs that the overlay it
/// would fly in cannot reach.
///
/// One per album on a page: two covers of the same album on one page would
/// share a tag.
class AlbumCoverHero extends StatelessWidget {
  final String albumId;
  final String? artworkPath;

  /// Corner radius of the cover at this end.
  final double radius;
  final Widget child;

  const AlbumCoverHero({
    super.key,
    required this.albumId,
    required this.artworkPath,
    required this.radius,
    required this.child,
  });

  static Object tagOf(String albumId) => 'album-cover-$albumId';

  @override
  Widget build(BuildContext context) =>
      Hero(tag: tagOf(albumId), flightShuttleBuilder: _shuttle, child: child);

  Widget _shuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    double radiusOf(BuildContext heroContext) =>
        heroContext.findAncestorWidgetOfExactType<AlbumCoverHero>()?.radius ??
        radius;
    final from = radiusOf(fromHeroContext);
    final to = radiusOf(toHeroContext);
    // A pop runs the route's animation backwards, from 1 to 0.
    final (atZero, atOne) = direction == HeroFlightDirection.push
        ? (from, to)
        : (to, from);
    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) => ClipRRect(
        borderRadius: BorderRadius.circular(
          lerpDouble(atZero, atOne, animation.value)!,
        ),
        child: child,
      ),
      child: ArtworkImage(artworkPath, placeholder: AppIcons.album),
    );
  }
}
