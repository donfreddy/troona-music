import 'package:flutter/material.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';

/// A circular icon button with a flat glass fill.
///
/// **No [BackdropFilter]** — icon buttons are small surfaces scattered across
/// the player screen.  Using blur on each one would exceed the two-filter
/// budget and cause GPU pressure.  A flat fill drawn from [GlassTheme.card]
/// is visually sufficient and consistent with Apple Music's player controls.
///
/// ### Size presets
///
/// | [GlassIconButtonSize] | Diameter | Icon size | Typical use           |
/// |-----------------------|----------|-----------|-----------------------|
/// | `sm`                  | 32 px    | 16 px     | Secondary controls    |
/// | `md`                  | 44 px    | 22 px     | Standard controls     |
/// | `lg`                  | 56 px    | 28 px     | Primary action (play) |
///
/// ### Variants
///
/// - Default — glass fill from [GlassTheme.card]; secondary controls.
/// - **[GlassIconButton.accent]** — solid accent fill; primary play/pause button.
///
/// Both variants animate to 90 % scale on press (iOS haptic-style feedback).
///
/// ```dart
/// // Play/pause — primary, large
/// GlassIconButton.accent(
///   icon: isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
///   size: GlassIconButtonSize.lg,
///   onTap: _togglePlayPause,
/// )
///
/// // Skip — secondary, medium
/// GlassIconButton(
///   icon: CupertinoIcons.forward_fill,
///   size: GlassIconButtonSize.md,
///   onTap: _skipNext,
/// )
/// ```
class GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final GlassIconButtonSize size;

  /// Optional icon colour override.  Defaults to [AppColors.labelPrimary].
  final Color? iconColor;

  final _GlassIconVariant _variant;

  /// Glass-fill variant — secondary controls.
  const GlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = GlassIconButtonSize.md,
    this.iconColor,
  }) : _variant = _GlassIconVariant.glass;

  /// Accent-fill variant — primary action (play/pause).
  const GlassIconButton.accent({
    super.key,
    required this.icon,
    this.onTap,
    this.size = GlassIconButtonSize.lg,
    this.iconColor,
  }) : _variant = _GlassIconVariant.accent;

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

enum GlassIconButtonSize { sm, md, lg }

enum _GlassIconVariant { glass, accent }

class _GlassIconButtonState extends State<GlassIconButton> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    setState(() => _pressed = true);
  }

  void _onTapUp(TapUpDetails _) => setState(() => _pressed = false);
  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isAccent = widget._variant == _GlassIconVariant.accent;
    final isDisabled = widget.onTap == null;

    final double diameter = switch (widget.size) {
      GlassIconButtonSize.sm => 32,
      GlassIconButtonSize.md => 44,
      GlassIconButtonSize.lg => 56,
    };

    final double iconSize = switch (widget.size) {
      GlassIconButtonSize.sm => 16,
      GlassIconButtonSize.md => 22,
      GlassIconButtonSize.lg => 28,
    };

    final Color bgColor;
    final Color resolvedIconColor;

    if (isAccent) {
      bgColor = colors.accent;
      resolvedIconColor = widget.iconColor ?? colors.accentForeground;
    } else {
      bgColor = GlassTheme.card(context).fill;
      resolvedIconColor = widget.iconColor ?? colors.labelPrimary;
    }

    final body = AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: isDisabled ? 0.38 : 1.0,
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeInOut,
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: isAccent
                ? null
                : Border.all(
                    color: Colors.white.withValues(alpha: .12),
                    width: 0.5,
                  ),
          ),
          child: Icon(widget.icon, color: resolvedIconColor, size: iconSize),
        ),
      ),
    );

    if (isDisabled) return body;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: body,
    );
  }
}
