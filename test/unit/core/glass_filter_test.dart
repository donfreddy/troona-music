import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/components/glass_filter.dart';

/// [matrix] applied to [color], as the engine does (channels in 0..255).
(double, double, double) _apply(List<double> matrix, Color color) {
  final rgb = [color.r * 255, color.g * 255, color.b * 255];
  double channel(int row) =>
      [
        for (var i = 0; i < 3; i++) matrix[row * 5 + i] * rgb[i],
      ].reduce((a, b) => a + b) +
      matrix[row * 5 + 4];
  return (channel(0), channel(1), channel(2));
}

double _luma((double, double, double) c) =>
    0.2126 * c.$1 + 0.7152 * c.$2 + 0.0722 * c.$3;

void main() {
  final boost = GlassFilter.saturationMatrix(GlassFilter.saturation);

  test('greys stay grey', () {
    final (r, g, b) = _apply(boost, const Color(0xFF808080));
    expect(r, closeTo(128, 1e-6));
    expect(g, closeTo(128, 1e-6));
    expect(b, closeTo(128, 1e-6));
  });

  test('luminance is kept, so contrast over the glass does not move', () {
    const violet = Color(0xFF6A3D9A);
    final before = _apply(GlassFilter.saturationMatrix(1), violet);
    expect(_luma(_apply(boost, violet)), closeTo(_luma(before), 1e-6));
  });

  test('colours move away from grey', () {
    const muted = Color(0xFF7A6A8A);
    final (r, g, b) = _apply(boost, muted);
    expect(b - g, greaterThan((0x8A - 0x6A).toDouble()));
    expect(r, inInclusiveRange(0, 255));
  });

  test('a saturation of 1 changes nothing', () {
    const color = Color(0xFF336699);
    final (r, g, b) = _apply(GlassFilter.saturationMatrix(1), color);
    expect((r, g, b), (0x33.toDouble(), 0x66.toDouble(), 0x99.toDouble()));
  });

  test('an exposure of 1 is the saturation matrix alone', () {
    expect(
      GlassFilter.materialMatrix(1.25, 1),
      GlassFilter.saturationMatrix(1.25),
    );
  });

  test('an exposure of 0.5 halves white and keeps black', () {
    final half = GlassFilter.materialMatrix(1.25, 0.5);
    final (r, g, b) = _apply(half, const Color(0xFFFFFFFF));
    for (final c in [r, g, b]) {
      expect(c, closeTo(127.5, 1e-9));
    }
    expect(_apply(half, const Color(0xFF000000)), (0.0, 0.0, 0.0));
  });
}
