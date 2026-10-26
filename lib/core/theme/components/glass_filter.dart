import 'dart:ui';

/// Backdrop filter of every glass surface: blur plus the saturation boost of
/// iOS materials, so colours behind the glass stay rich instead of greying.
///
/// The saturation matrix keeps luminance (Rec. 709 weights): text contrast
/// over the glass does not move.
abstract final class GlassFilter {
  /// Saturation applied behind the glass; 1 leaves colours as they are.
  static const saturation = 1.6;

  static ImageFilter of(double sigma) => ImageFilter.compose(
    outer: ImageFilter.blur(
      sigmaX: sigma,
      sigmaY: sigma,
      tileMode: TileMode.clamp,
    ),
    inner: ColorFilter.matrix(saturationMatrix(saturation)),
  );

  /// Colour matrix scaling saturation by [s] around the luminance axis.
  static List<double> saturationMatrix(double s) {
    const r = 0.2126, g = 0.7152, b = 0.0722;
    final i = 1 - s;
    return [
      r * i + s, g * i, b * i, 0, 0, //
      r * i, g * i + s, b * i, 0, 0, //
      r * i, g * i, b * i + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }
}
