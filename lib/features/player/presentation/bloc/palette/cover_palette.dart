import 'dart:io';

import 'package:flutter/material.dart';
import 'package:palette_generator_master/palette_generator_master.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';

/// The colours a cover image lends the screens around it, read once per
/// image and kept by its path: the song playing (`TrackPaletteCubit`) and
/// the album or artist page showing that same cover get the very same
/// colours.
abstract final class CoverPalette {
  CoverPalette._();

  /// Covers kept: a screen of albums and a few songs.
  static const capacity = 64;

  /// In the order they were last used, the oldest first.
  static final _cache = <String, TrackPaletteState>{};

  /// Reads the swatches of the image at a path. Replaced in tests.
  @visibleForTesting
  static Future<CoverSwatches> Function(String path) read = _read;

  static Future<CoverSwatches> _read(String path) async {
    final palette = await PaletteGeneratorMaster.fromImageProvider(
      FileImage(File(path)),
      size: const Size(64, 64),
    );
    return (
      vibrant: palette.vibrantColor?.color,
      dominant: palette.dominantColor?.color,
      darkVibrant: palette.darkVibrantColor?.color,
      muted: palette.mutedColor?.color,
    );
  }

  /// The colours of [path] if already read, at once.
  static TrackPaletteState? cached(String path) {
    final hit = _cache.remove(path);
    if (hit != null) _cache[path] = hit; // Most recent last.
    return hit;
  }

  /// The colours of the image at [path], read once; null when it cannot be
  /// read.
  static Future<TrackPaletteState?> of(String path) async {
    final hit = cached(path);
    if (hit != null) return hit;
    try {
      final colours = fromSwatches(await read(path));
      _cache[path] = colours;
      if (_cache.length > capacity) _cache.remove(_cache.keys.first);
      return colours;
    } catch (_) {
      return null;
    }
  }

  /// The accent and the two glow colours made from a cover's swatches.
  @visibleForTesting
  static TrackPaletteState fromSwatches(CoverSwatches swatches) {
    final primary =
        swatches.vibrant ?? swatches.dominant ?? const Color(0xFF1A0533);
    final secondary = swatches.darkVibrant ?? swatches.muted ?? primary;

    Color accent(Color c) {
      final hsl = HSLColor.fromColor(c);
      return hsl
          .withSaturation((hsl.saturation * 1.2).clamp(0.5, 0.9))
          .withLightness(0.6)
          .toColor();
    }

    Color glow(Color c, {required bool top}) {
      final hsl = HSLColor.fromColor(c);
      return hsl
          .withSaturation((hsl.saturation * 1.1).clamp(0.4, 0.9))
          .withLightness(top ? 0.25 : 0.15)
          .toColor();
    }

    return TrackPaletteState(
      primary: accent(primary),
      secondary: accent(secondary),
      backgroundColorA: glow(primary, top: true),
      backgroundColorB: glow(secondary, top: false),
    );
  }

  @visibleForTesting
  static void clear() {
    _cache.clear();
    read = _read;
  }
}

/// The swatches a cover's colours are made from.
typedef CoverSwatches = ({
  Color? vibrant,
  Color? dominant,
  Color? darkVibrant,
  Color? muted,
});
