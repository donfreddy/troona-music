import 'package:flutter/material.dart';

/// Whether the tab pages, and the pages pushed over them, glow in the
/// colours of the song playing; off, they are black (the "Black
/// background" setting). Carried by the theme, as [GlassSettings] is.
///
/// Album, artist and Now Playing keep their glow either way: it says
/// whose page it is.
@immutable
final class AmbientGlow extends ThemeExtension<AmbientGlow> {
  final bool on;

  const AmbientGlow(this.on);

  /// The setting where [context] is; on outside the app's theme.
  static bool of(BuildContext context) =>
      Theme.of(context).extension<AmbientGlow>()?.on ?? true;

  @override
  AmbientGlow copyWith({bool? on}) => AmbientGlow(on ?? this.on);

  @override
  AmbientGlow lerp(AmbientGlow? other, double t) =>
      other == null || t < 0.5 ? this : other;

  @override
  bool operator ==(Object other) => other is AmbientGlow && other.on == on;

  @override
  int get hashCode => on.hashCode;
}
