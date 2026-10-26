import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Local artwork decoded at its displayed size.
///
/// A bare [Image.file] decodes the whole file (500 px JPEGs here) even for a
/// 42 px thumbnail; across a scrolling list that multiplies memory and
/// decode time. This sizes the decoded bitmap to the layout width.
///
/// Artwork is extracted as square images, so constraining the width keeps
/// [BoxFit.cover] sharp.
class ArtworkImage extends StatelessWidget {
  /// Absolute file path; a `file://` URI is accepted too.
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final ImageErrorWidgetBuilder? errorBuilder;

  const ArtworkImage(
    this.path, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
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
      errorBuilder: errorBuilder ??
          (context, error, stackTrace) => Container(
                width: width,
                height: height,
                color: Colors.white.withValues(alpha: .06),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: Colors.white24,
                  size: 24,
                ),
              ),
    );

    final explicit = width;
    if (explicit != null) return image(explicit);
    return LayoutBuilder(
      builder: (_, constraints) => image(constraints.maxWidth),
    );
  }
}
