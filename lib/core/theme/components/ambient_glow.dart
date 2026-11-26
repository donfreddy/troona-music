import 'package:flutter/material.dart';
import 'package:troona/core/theme/primitives/color_primitives.dart';

/// The app's ambient glow, carried by the theme as [GlassSettings] is:
/// whether the tab pages, and the pages pushed over them, glow in the
/// colours of the song playing (off, they are black: the "Black
/// background" setting), and the glow shown with no cover, from the accent.
///
/// Album, artist and Now Playing keep their glow either way: it says
/// whose page it is.
@immutable
final class AmbientGlow extends ThemeExtension<AmbientGlow> {
  final bool on;

  /// The glow with no cover to take colours from.
  final Color top;
  final Color edge;

  const AmbientGlow(
    this.on, {
    this.top = ColorPrimitives.ambientTop,
    this.edge = ColorPrimitives.ambientEdge,
  });

  static AmbientGlow _of(BuildContext context) =>
      Theme.of(context).extension<AmbientGlow>() ?? const AmbientGlow(true);

  /// The setting where [context] is; on outside the app's theme.
  static bool of(BuildContext context) => _of(context).on;

  /// The glow with no cover where [context] is: lilac outside the app's
  /// theme.
  static (Color, Color) colorsOf(BuildContext context) {
    final glow = _of(context);
    return (glow.top, glow.edge);
  }

  @override
  AmbientGlow copyWith({bool? on, Color? top, Color? edge}) =>
      AmbientGlow(on ?? this.on, top: top ?? this.top, edge: edge ?? this.edge);

  /// Never blended: the glow cross-fades its own colours.
  @override
  AmbientGlow lerp(AmbientGlow? other, double t) =>
      other == null || t < 0.5 ? this : other;

  @override
  bool operator ==(Object other) =>
      other is AmbientGlow &&
      other.on == on &&
      other.top == top &&
      other.edge == edge;

  @override
  int get hashCode => Object.hash(on, top, edge);
}
