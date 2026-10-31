import 'package:flutter/material.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/shared/widgets/app_button.dart';

/// An icon on its own, without a fill: row options, the close of a sheet,
/// the clear of a field, the mini player controls.
///
/// A glass circle is a [GlassIconButton]. This one takes 44 x 44 dp, the
/// touch target, whatever the icon [size]. The [tooltip] is required: it is
/// also the label screen readers read. Pass `onPressed: null` to disable it.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;

  /// Defaults to [AppColors.labelSecondary].
  final Color? color;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: size),
      style: IconButton.styleFrom(
        foregroundColor: color ?? colors.labelSecondary,
        disabledForegroundColor: colors.labelTertiary,
        minimumSize: const Size.square(AppButton.minTouchTarget),
        padding: EdgeInsets.zero,
        // The minimum size above is the touch target: no 48 dp padding.
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
