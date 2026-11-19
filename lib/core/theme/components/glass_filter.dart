import 'dart:ui';

/// Backdrop filter of every glass surface: blur plus the saturation boost of
/// iOS materials, so colours behind the glass stay rich instead of greying.
///
/// The saturation matrix keeps luminance (Rec. 709 weights): text contrast
/// over the glass does not move.
abstract final class GlassFilter {
  /// Saturation applied behind the glass; 1 leaves colours as they are.
  static const saturation = 1.6;

  /// Blur of [sigma]; [saturation] defaults to the chrome boost, and 1
  /// keeps colours as they are. [exposure] scales what the glass lets
  /// through: 1 leaves it, 0.5 halves it, so a white cover under the glass
  /// cannot wash out white text on it (black stays black).
  ///
  /// One filter per material, kept: the glass rebuilds often (a scroll
  /// under the header, the bar with the player), and each build allocated
  /// a composed filter and its matrix.
  static ImageFilter of(
    double sigma, {
    double saturation = GlassFilter.saturation,
    double exposure = 1,
  }) {
    final key = (sigma, saturation, exposure);
    final kept = _filters[key];
    if (kept != null) return kept;
    // Materials come from the presets, a handful; a caller animating a
    // value would otherwise fill the cache.
    if (_filters.length >= _maxFilters) _filters.clear();
    return _filters[key] = ImageFilter.compose(
      outer: ImageFilter.blur(
        sigmaX: sigma,
        sigmaY: sigma,
        tileMode: TileMode.clamp,
      ),
      inner: ColorFilter.matrix(materialMatrix(saturation, exposure)),
    );
  }

  static final _filters = <(double, double, double), ImageFilter>{};
  static const _maxFilters = 32;

  /// Colour matrix scaling saturation by [s] around the luminance axis.
  static List<double> saturationMatrix(double s) => materialMatrix(s, 1);

  /// Colour matrix scaling saturation by [s] around the luminance axis,
  /// then brightness by [e]. One matrix: still one pass under the blur.
  static List<double> materialMatrix(double s, double e) {
    const r = 0.2126, g = 0.7152, b = 0.0722;
    final i = 1 - s;
    return [
      (r * i + s) * e, g * i * e, b * i * e, 0, 0, //
      r * i * e, (g * i + s) * e, b * i * e, 0, 0, //
      r * i * e, g * i * e, (b * i + s) * e, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }
}
