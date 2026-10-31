import 'package:flutter/material.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';

/// The app's small pill labels.
///
/// - [AppBadge.new]: a neutral glass pill for facts about a page (a year,
///   a song count, listeners), with an optional accent [icon].
/// - [AppBadge.accent]: an accent pill in capitals that names a kind or a
///   state (Artist, Album, Latest).
class AppBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool _accent;

  const AppBadge(this.label, {super.key, this.icon}) : _accent = false;

  const AppBadge.accent(this.label, {super.key}) : icon = null, _accent = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final icon = this.icon;

    if (_accent) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colors.accent.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: colors.accent,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: .6,
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: Colors.white.withValues(alpha: .12),
          width: .8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        // A span, not a Row: a long label wraps under a large font.
        child: Text.rich(
          TextSpan(
            children: [
              if (icon != null) ...[
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(icon, size: 11, color: colors.accent),
                ),
                const WidgetSpan(child: SizedBox(width: AppSpacing.xs)),
              ],
              TextSpan(text: label),
            ],
          ),
          style: TextStyle(
            color: colors.labelSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
