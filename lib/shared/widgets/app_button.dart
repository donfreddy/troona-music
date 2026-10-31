import 'package:flutter/material.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';

enum AppButtonSize {
  /// 32 dp pill, 13 pt label: in-line actions (See all, Shuffle).
  small,

  /// 44 dp pill, 15 pt label: the actions of a card, a page or a sheet.
  medium,
}

enum _Variant { primary, secondary, text }

/// The app's text buttons, as a pill:
///
/// - [AppButton.primary]: accent fill, the action a surface leads to.
/// - [AppButton.secondary]: glass fill, an action next to it or on its own.
/// - [AppButton.text]: no fill, a dismissive action (Later, Skip).
///
/// Every size takes at least 44 x 44 dp of layout, the touch target; a small
/// pill is drawn centred in it. A long label wraps under a large font. Pass
/// `onPressed: null` to disable it.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  /// Drawn before [label]: in the accent colour on a secondary button.
  final IconData? icon;

  /// Drawn after [label] (a chevron that turns, for instance).
  final Widget? trailing;

  final AppButtonSize size;

  /// Takes the full width it is given.
  final bool expanded;

  final _Variant _variant;

  const AppButton.primary(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.trailing,
    this.size = AppButtonSize.medium,
    this.expanded = false,
  }) : _variant = _Variant.primary;

  const AppButton.secondary(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.trailing,
    this.size = AppButtonSize.medium,
    this.expanded = false,
  }) : _variant = _Variant.secondary;

  const AppButton.text(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.trailing,
    this.size = AppButtonSize.medium,
    this.expanded = false,
  }) : _variant = _Variant.text;

  /// Smallest layout size, whatever the [size].
  static const double minTouchTarget = 44;

  /// Smallest drawn height of the pill.
  static double pillHeight(AppButtonSize size) => switch (size) {
    AppButtonSize.small => 32,
    AppButtonSize.medium => 44,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final small = size == AppButtonSize.small;
    final enabled = onPressed != null;

    final (
      fill,
      pressedFill,
      border,
      foreground,
      iconColor,
    ) = switch (_variant) {
      _Variant.primary => (
        colors.accent,
        Color.lerp(colors.accent, Colors.white, .16)!,
        null,
        colors.accentForeground,
        colors.accentForeground,
      ),
      _Variant.secondary => (
        Colors.white.withValues(alpha: .12),
        Colors.white.withValues(alpha: .2),
        Colors.white.withValues(alpha: .15),
        colors.labelPrimary,
        colors.accent,
      ),
      _Variant.text => (
        Colors.transparent,
        Colors.white.withValues(alpha: .08),
        null,
        colors.labelSecondary,
        colors.labelSecondary,
      ),
    };
    final icon = this.icon;
    final trailing = this.trailing;

    final button = TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(minTouchTarget, minTouchTarget),
        ),
        // The minimum size above is the touch target: no 48 dp padding.
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: small ? AppSpacing.md : AppSpacing.xl,
            vertical: small ? 6 : 10,
          ),
        ),
        foregroundColor: WidgetStatePropertyAll(
          enabled ? foreground : colors.labelTertiary,
        ),
        // The pill below shows the press; an ink splash would cover the
        // whole touch target, larger than a small pill.
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        // From the theme, so the label keeps the app's font family.
        textStyle: WidgetStatePropertyAll(
          (Theme.of(context).textTheme.labelLarge ?? const TextStyle())
              .copyWith(
                fontSize: small ? 13 : 15,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
        ),
        backgroundBuilder: (context, states, child) {
          final pressed =
              states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.focused);
          final disabled = states.contains(WidgetState.disabled);
          final color = pressed ? pressedFill : fill;
          return Center(
            widthFactor: expanded ? null : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              constraints: BoxConstraints(
                minHeight: pillHeight(size),
                minWidth: expanded ? double.infinity : 0,
              ),
              decoration: ShapeDecoration(
                color: disabled
                    ? color.withValues(alpha: color.a * .38)
                    : color,
                shape: StadiumBorder(
                  side: border == null
                      ? BorderSide.none
                      : BorderSide(color: border, width: .5),
                ),
              ),
              child: Center(
                widthFactor: expanded ? null : 1,
                heightFactor: 1,
                child: child,
              ),
            ),
          );
        },
      ),
      // A span, not a Row: the label wraps around the icon under a large
      // font, whatever the width the button gets.
      child: Text.rich(
        TextSpan(
          children: [
            if (icon != null) ...[
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(
                  icon,
                  size: small ? 14 : 18,
                  color: enabled ? iconColor : colors.labelTertiary,
                ),
              ),
              const WidgetSpan(child: SizedBox(width: AppSpacing.sm)),
            ],
            TextSpan(text: label),
            if (trailing != null) ...[
              const WidgetSpan(child: SizedBox(width: AppSpacing.xs)),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: trailing,
              ),
            ],
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
