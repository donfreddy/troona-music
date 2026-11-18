import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

/// An artist's photo that flies from their round card to their page,
/// where it fills the header, and back: the page opens on the face that
/// was tapped.
///
/// Only a downloaded photo flies, the same file at both ends. A card
/// showing a cover has none: the page shows that cover as a blurred glow,
/// which a sharp cover growing to the width of the screen would not
/// become.
///
/// In flight, the circle opens into the header's rectangle while the plain
/// photo cross-fades into the header's own (its fade into the page, its
/// dark top): neither end changes when the flight lands.
class ArtistPhotoHero extends StatelessWidget {
  final String artistId;

  /// The downloaded photo, as a file path.
  final String photo;

  /// True at the card's end, a circle; false at the page's.
  final bool round;

  final Widget child;

  const ArtistPhotoHero({
    super.key,
    required this.artistId,
    required this.photo,
    required this.round,
    required this.child,
  });

  static Object tagOf(String artistId) => 'artist-photo-$artistId';

  @override
  Widget build(BuildContext context) =>
      Hero(tag: tagOf(artistId), flightShuttleBuilder: _shuttle, child: child);

  Widget _shuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    // The route's animation is 1 with the page in, whichever way it runs:
    // its value is how far the photo looks like the page's.
    final pageEnd = [fromHeroContext, toHeroContext].firstWhere(
      (end) =>
          end.findAncestorWidgetOfExactType<ArtistPhotoHero>()?.round == false,
      orElse: () => toHeroContext,
    );
    final page = (pageEnd.widget as Hero).child;
    final plain = ArtworkImage(photo, placeholder: AppIcons.artist);
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) {
        final t = animation.value.clamp(0.0, 1.0);
        return LayoutBuilder(
          builder: (_, box) => ClipRRect(
            borderRadius: BorderRadius.circular(
              lerpDouble(box.biggest.shortestSide / 2, 0, t)!,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(opacity: 1 - t, child: plain),
                Opacity(opacity: t, child: page),
              ],
            ),
          ),
        );
      },
    );
  }
}
