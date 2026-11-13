import 'package:flutter/material.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';

/// Facts about a page (a year, a song count, a length, a size) as one line
/// of secondary text, "2024 • 7 songs • 11 min": the quiet way to state
/// them. A pill ([AppBadge]) is for a rare state worth noticing, such as
/// Lossless, not for every fact.
///
/// Null and empty parts are left out; with none, it shows nothing. It wraps
/// under a large font instead of overflowing.
class MetaLine extends StatelessWidget {
  final List<String?> parts;
  final TextAlign textAlign;

  /// Smaller and dimmer, for the footnote at the end of a page.
  final bool footnote;

  const MetaLine(
    this.parts, {
    super.key,
    this.textAlign = TextAlign.start,
    this.footnote = false,
  });

  static const separator = ' • ';

  /// [parts] as shown, or null when there is nothing to show.
  static String? join(List<String?> parts) {
    final shown = [
      for (final part in parts)
        if (part != null && part.isNotEmpty) part,
    ];
    return shown.isEmpty ? null : shown.join(separator);
  }

  @override
  Widget build(BuildContext context) {
    final text = join(parts);
    if (text == null) return const SizedBox.shrink();
    final colors = context.colors;
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        color: footnote ? colors.labelTertiary : colors.labelSecondary,
        fontSize: footnote ? 13 : 15,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
