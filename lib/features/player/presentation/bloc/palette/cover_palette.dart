import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:palette_generator_master/palette_generator_master.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';

/// The colours a cover image lends the screens around it, read once per
/// version of its file and kept by its path: the song playing
/// (`TrackPaletteCubit`) and a page showing that same file get the very
/// same colours.
abstract final class CoverPalette {
  CoverPalette._();

  /// Covers kept: a screen of albums and a few songs.
  static const capacity = 64;

  /// Side of the image the colours are read from: a cover decoded whole
  /// (an artist photo is 1000 x 1000) would be read pixel by pixel.
  static const _side = 64;

  /// In the order they were last used, the oldest first. Colours null: the
  /// image could not be read, not tried again until its file changes.
  static final _cache =
      <String, ({DateTime? stamp, TrackPaletteState? colours})>{};

  /// Reads in flight, shared by everyone asking for the same image.
  static final _reads = <String, Future<TrackPaletteState?>>{};

  /// Reads the swatches of the image at a path. Replaced in tests.
  @visibleForTesting
  static Future<CoverSwatches> Function(String path) read = _read;

  /// When the file at a path last changed, null when there is none: an
  /// artist's photo is downloaded again to the same path. Replaced in
  /// tests.
  @visibleForTesting
  static Future<DateTime?> Function(String path) stampOf = _stamp;

  static Future<DateTime?> _stamp(String path) async {
    final stat = await File(path).stat();
    return stat.type == FileSystemEntityType.notFound ? null : stat.modified;
  }

  // Decoded small and straight from the file: a file that is gone or
  // broken fails at once (an image provider would wait for a timeout), and
  // nothing lands in the image cache.
  static Future<CoverSwatches> _read(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: _side,
      targetHeight: _side,
    );
    final ui.Image image;
    try {
      image = (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
    try {
      final palette = await PaletteGeneratorMaster.fromImage(image);
      return (
        vibrant: palette.vibrantColor?.color,
        dominant: palette.dominantColor?.color,
        darkVibrant: palette.darkVibrantColor?.color,
        muted: palette.mutedColor?.color,
      );
    } finally {
      image.dispose();
    }
  }

  /// The colours of [path] if already read, at once. They may be of an
  /// older file at that path: [of] tells.
  static TrackPaletteState? cached(String path) {
    final hit = _cache.remove(path);
    if (hit == null) return null;
    _cache[path] = hit; // Most recent last.
    return hit.colours;
  }

  /// The colours of the image at [path], read once per version of its
  /// file; null when it cannot be read.
  static Future<TrackPaletteState?> of(String path) =>
      _reads[path] ??= _of(path).whenComplete(() {
        // A block, not an arrow: remove returns this very future, which
        // whenComplete would then wait for.
        _reads.remove(path);
      });

  static Future<TrackPaletteState?> _of(String path) async {
    final DateTime? stamp;
    try {
      stamp = await stampOf(path);
    } catch (_) {
      return null;
    }
    final hit = _cache.remove(path);
    if (hit != null && hit.stamp == stamp) {
      _cache[path] = hit;
      return hit.colours;
    }
    TrackPaletteState? colours;
    if (stamp != null) {
      try {
        colours = fromSwatches(await read(path));
      } catch (_) {}
    }
    _cache[path] = (stamp: stamp, colours: colours);
    if (_cache.length > capacity) _cache.remove(_cache.keys.first);
    return colours;
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
    _reads.clear();
    read = _read;
    stampOf = _stamp;
  }
}

/// The swatches a cover's colours are made from.
typedef CoverSwatches = ({
  Color? vibrant,
  Color? dominant,
  Color? darkVibrant,
  Color? muted,
});
