import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Text colours for a surface painted with the glow of the song playing:
/// a light tint of the glow's hue instead of a fixed grey, each level as
/// faint as it may be while keeping its contrast floor over the brightest
/// pixel the glow paints.
///
/// The glow is always dark (see `DynamicBackground.fitForText`), so text
/// is always light: no switch to dark text is needed.
@immutable
final class PaletteInk {
  /// Titles and the line sung: white.
  final Color primary;

  /// Long text read at once (plain lyrics): the tint, opaque.
  final Color body;

  /// Small secondary text (13 to 14 sp): [secondaryContrast] at least.
  final Color secondary;

  /// Large text next to [primary] (the lines around the one sung):
  /// [nearContrast] at least.
  final Color near;

  /// Large text further away: [farContrast] at least.
  final Color far;

  const PaletteInk._({
    required this.primary,
    required this.body,
    required this.secondary,
    required this.near,
    required this.far,
  });

  /// WCAG AA for normal text.
  static const secondaryContrast = 4.5;

  /// WCAG AA for large text (lyrics are 26 sp bold).
  static const nearContrast = 3.0;

  /// Faded on purpose, yet never gone.
  static const farContrast = 2.0;

  /// Below this saturation the glow is a grey, and so is the tint: a grey
  /// cover never gets a hue it does not have.
  static const greyBelow = 0.15;

  static const tintSaturation = 0.35;
  static const tintLightness = 0.85;

  /// The ink over a glow of [colorA] and [colorB], as the background
  /// paints them (already fitted for text). The tint takes [colorA]'s hue,
  /// the glow's main colour; the floors hold over both glows and black.
  static PaletteInk of(Color colorA, Color colorB) {
    final tint = tintOf(colorA);
    final grounds = [
      glowPeakOf(colorA),
      glowPeakOf(colorB),
      const Color(0xFF000000),
    ];
    Color level(double floor) => tint.withValues(
      alpha: [
        for (final g in grounds) alphaFor(tint, g, floor),
      ].reduce((a, b) => a > b ? a : b),
    );
    return PaletteInk._(
      primary: const Color(0xFFFFFFFF),
      body: tint,
      secondary: level(secondaryContrast),
      near: level(nearContrast),
      far: level(farContrast),
    );
  }

  /// A light colour of [glow]'s hue, neutral for a grey.
  @visibleForTesting
  static Color tintOf(Color glow) {
    final hsl = HSLColor.fromColor(glow);
    return hsl
        .withSaturation(hsl.saturation < greyBelow ? 0 : tintSaturation)
        .withLightness(tintLightness)
        .toColor();
  }

  /// The least alpha at which [ink] over [ground] reaches [floor], rounded
  /// up to the next of the 255 steps a colour is drawn with; 1 when even
  /// opaque it cannot.
  @visibleForTesting
  static double alphaFor(Color ink, Color ground, double floor) {
    if (contrastOf(Color.alphaBlend(ink.withValues(alpha: 1), ground), ground) <
        floor) {
      return 1;
    }
    var low = 0.0;
    var high = 1.0;
    for (var i = 0; i < 20; i++) {
      final mid = (low + high) / 2;
      final blended = Color.alphaBlend(ink.withValues(alpha: mid), ground);
      if (contrastOf(blended, ground) >= floor) {
        high = mid;
      } else {
        low = mid;
      }
    }
    return ((high * 255).ceil() / 255).clamp(0.0, 1.0);
  }

  /// The brightest pixel a glow of [color] paints on black: an upper bound
  /// of both glows in both tones (at most 12 % towards white, 92 % alpha).
  /// Where the glows overlap, each is well below its peak.
  static Color glowPeakOf(Color color) => Color.alphaBlend(
    Color.lerp(color, const Color(0xFFFFFFFF), .12)!.withValues(alpha: .92),
    const Color(0xFF000000),
  );

  /// WCAG contrast ratio of two opaque colours.
  static double contrastOf(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final (hi, lo) = la > lb ? (la, lb) : (lb, la);
    return (hi + 0.05) / (lo + 0.05);
  }

  /// Between two inks, for a glow moving from one song's to the next.
  static PaletteInk lerp(PaletteInk a, PaletteInk b, double t) => PaletteInk._(
    primary: Color.lerp(a.primary, b.primary, t)!,
    body: Color.lerp(a.body, b.body, t)!,
    secondary: Color.lerp(a.secondary, b.secondary, t)!,
    near: Color.lerp(a.near, b.near, t)!,
    far: Color.lerp(a.far, b.far, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is PaletteInk &&
      other.primary == primary &&
      other.body == body &&
      other.secondary == secondary &&
      other.near == near &&
      other.far == far;

  @override
  int get hashCode => Object.hash(primary, body, secondary, near, far);
}
