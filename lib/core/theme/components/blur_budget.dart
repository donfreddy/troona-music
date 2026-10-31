import 'package:flutter/widgets.dart';

/// Marks a subtree whose screen already shows every [BackdropFilter] it can
/// afford: Now Playing (its two blurs) and the content of a modal sheet.
///
/// Surfaces opened from below it, such as a sheet or an action menu, are
/// opaque: [GlassTheme.aboveGlass] reads it from the context they are opened
/// from.
class BlurBudgetSpent extends InheritedWidget {
  const BlurBudgetSpent({super.key, required super.child});

  /// Whether [context] is below a [BlurBudgetSpent].
  static bool isSpent(BuildContext context) =>
      context.getInheritedWidgetOfExactType<BlurBudgetSpent>() != null;

  @override
  bool updateShouldNotify(BlurBudgetSpent oldWidget) => false;
}
