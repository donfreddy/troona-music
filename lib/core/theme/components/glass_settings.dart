import 'package:flutter/material.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';

/// The glass quality the app draws with, carried by the theme: changing
/// the setting rebuilds every surface that reads it ([GlassTheme]), with
/// no static state to keep in step.
///
/// Never [GlassQuality.auto]: the app resolves it against the tier
/// detected on the device first ([effective]).
@immutable
final class GlassSettings extends ThemeExtension<GlassSettings> {
  final GlassQuality quality;

  const GlassSettings(this.quality) : assert(quality != GlassQuality.auto);

  /// What [setting] draws with on a device detected as [detected].
  static GlassQuality effective(GlassQuality setting, GlassQuality detected) =>
      setting == GlassQuality.auto ? detected : setting;

  @override
  GlassSettings copyWith({GlassQuality? quality}) =>
      GlassSettings(quality ?? this.quality);

  /// A tier is not blended: the theme's change animation switches it
  /// halfway.
  @override
  GlassSettings lerp(GlassSettings? other, double t) =>
      other == null || t < 0.5 ? this : other;

  @override
  bool operator ==(Object other) =>
      other is GlassSettings && other.quality == quality;

  @override
  int get hashCode => quality.hashCode;
}
