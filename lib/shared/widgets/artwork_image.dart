import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';

/// Local artwork decoded at its displayed size, or [ArtworkPlaceholder]
/// when there is none.
///
/// A bare [Image.file] decodes the whole file (500 px JPEGs here) even for a
/// 42 px thumbnail; across a scrolling list that multiplies memory and
/// decode time. This sizes the decoded bitmap to the layout width.
///
/// Artwork is extracted as square images, so constraining the width keeps
/// [BoxFit.cover] sharp.
class ArtworkImage extends StatelessWidget {
  /// Absolute file path; a `file://` URI is accepted too. Null or empty
  /// shows the placeholder.
  final String? path;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// What the artwork stands for: a song, an album, an artist. Drawn on
  /// the placeholder, without a path or when the file cannot be read.
  final IconData placeholder;

  /// Replaces the placeholder when the file cannot be read.
  final ImageErrorWidgetBuilder? errorBuilder;

  const ArtworkImage(
    this.path, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder = AppIcons.track,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final path = this.path;
    if (path == null || path.isEmpty) {
      return ArtworkPlaceholder(
        icon: placeholder,
        width: width,
        height: height,
      );
    }
    final file = File(
      path.startsWith('file:') ? Uri.parse(path).toFilePath() : path,
    );
    final dpr = MediaQuery.devicePixelRatioOf(context);

    Widget image(double? logicalWidth) => Image.file(
      file,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: logicalWidth == null || !logicalWidth.isFinite
          ? null
          : math.max(1, (logicalWidth * dpr).round()),
      gaplessPlayback: true,
      errorBuilder:
          errorBuilder ??
          (_, _, _) => ArtworkPlaceholder(
            icon: placeholder,
            width: width,
            height: height,
          ),
    );

    final explicit = width;
    if (explicit != null) return image(explicit);
    return LayoutBuilder(
      builder: (_, constraints) => image(constraints.maxWidth),
    );
  }
}

/// Stands in for missing artwork: a faint square with [icon] in the middle,
/// sized to the room it gets. Fills its parent unless given a size; the
/// parent clips it to a rounded square or a circle.
///
/// Opaque, like a cover: whatever sits behind one (the record on the album
/// page, a Hero flight) must not show through it.
class ArtworkPlaceholder extends StatelessWidget {
  final IconData icon;
  final double? width;
  final double? height;

  const ArtworkPlaceholder({
    super.key,
    this.icon = AppIcons.track,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: Color.alphaBlend(
          Colors.white.withValues(alpha: .08),
          colors.bgSecondary,
        ),
        child: LayoutBuilder(
          builder: (_, constraints) {
            final side = math.min(constraints.maxWidth, constraints.maxHeight);
            return Center(
              child: Icon(
                icon,
                color: colors.labelTertiary,
                size: side.isFinite ? (side * .4).clamp(16, 64) : 24,
              ),
            );
          },
        ),
      ),
    );
  }
}
