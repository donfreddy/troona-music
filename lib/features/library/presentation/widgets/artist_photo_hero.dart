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

  /// The photo in flight.
  @visibleForTesting
  static const shuttleKey = ValueKey('artistPhotoShuttle');

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
    final pageEnd = [fromHeroContext, toHeroContext].firstWhere(
      (end) =>
          end.findAncestorWidgetOfExactType<ArtistPhotoHero>()?.round == false,
      orElse: () => toHeroContext,
    );
    final page = (pageEnd.widget as Hero).child;
    // Most often the page is the route coming or going, but a pop can land
    // on a page below (the artist's page, from a card on another one).
    final towardsPage = identical(pageEnd, toHeroContext);
    // Decoded once, at the width of the screen it grows to: sized by the
    // flight, it would be decoded again at each frame's size.
    final side = MediaQuery.sizeOf(flightContext).width;
    final plain = FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: ArtworkImage(
        photo,
        width: side,
        height: side,
        placeholder: AppIcons.artist,
      ),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) {
        // How far the flight went, whichever way the route runs (a pop
        // runs it from 1 to 0), then how far it looks like the page's.
        final v = animation.value.clamp(0.0, 1.0);
        final flown = direction == HeroFlightDirection.push ? v : 1 - v;
        final t = towardsPage ? flown : 1 - flown;
        return LayoutBuilder(
          builder: (_, box) => ClipRRect(
            key: shuttleKey,
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
