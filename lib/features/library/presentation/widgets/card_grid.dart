import 'package:flutter/rendering.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';

/// [columns] square covers across, each cell as tall as its cover and the
/// [textHeight] under it: no room left empty between the rows, and the
/// place of the nth card is known (the Library's index jumps to it).
class CardGrid extends SliverGridDelegate {
  final int columns;
  final double textHeight;

  const CardGrid({required this.columns, required this.textHeight});

  static const double _across = AppSpacing.md;
  static const double _down = AppSpacing.lg;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final cell =
        (constraints.crossAxisExtent - _across * (columns - 1)) / columns;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      crossAxisSpacing: _across,
      mainAxisSpacing: _down,
      mainAxisExtent: cell + textHeight,
    ).getLayout(constraints);
  }

  @override
  bool shouldRelayout(CardGrid old) =>
      old.columns != columns || old.textHeight != textHeight;
}
