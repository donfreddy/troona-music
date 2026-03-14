import 'package:flutter/material.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';

/// A glass-styled button with an iOS-inspired press animation.
///
/// Two variants are available:
///
/// - **[GlassButton]** (default) — translucent glass fill; secondary actions.
/// - **[GlassButton.filled]** — solid accent fill; primary / destructive actions.
///
/// Both variants scale to 95 % on press (iOS squeeze feedback) and restore on
/// release or cancel.  Pass `onTap: null` to disable the button; it renders at
/// reduced opacity.
///
/// ```dart
/// // Primary CTA
/// GlassButton.filled(label: 'Play All', onTap: _playAll)
///
/// // Secondary action with leading icon
/// GlassButton(
///   label: 'Add to Queue',
///   leading: const Icon(CupertinoIcons.add, size: 18),
///   onTap: _addToQueue,
/// )
/// ```
class GlassButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;

  /// Optional widget (e.g. [Icon]) placed to the left of [label].
  final Widget? leading;

  final _GlassButtonVariant _variant;

  /// Glass-fill variant — for secondary actions.
  const GlassButton({super.key, required this.label, this.onTap, this.leading})
    : _variant = _GlassButtonVariant.glass;

  /// Accent-fill variant — for primary actions.
  const GlassButton.filled({
    super.key,
    required this.label,
    this.onTap,
    this.leading,
  }) : _variant = _GlassButtonVariant.filled;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

enum _GlassButtonVariant { glass, filled }

class _GlassButtonState extends State<GlassButton> {
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
    final isFilled = widget._variant == _GlassButtonVariant.filled;
    final isDisabled = widget.onTap == null;

    // Resolve background and foreground colours by variant.
    final Color bgColor;
    final Color fgColor;

    if (isFilled) {
      bgColor = colors.accent;
      fgColor = colors.accentForeground;
    } else {
      final cfg = GlassTheme.card(context);
      bgColor = cfg.fill;
      fgColor = colors.labelPrimary;
    }

    final body = AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: isDisabled ? 0.38 : 1.0,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeInOut,
        child: _ButtonSurface(
          bgColor: bgColor,
          fgColor: fgColor,
          label: widget.label,
          leading: widget.leading,
          isFilled: isFilled,
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

// ─────────────────────────────────────────────────────────────────────────────

class _ButtonSurface extends StatelessWidget {
  final Color bgColor;
  final Color fgColor;
  final String label;
  final Widget? leading;
  final bool isFilled;

  const _ButtonSurface({
    required this.bgColor,
    required this.fgColor,
    required this.label,
    required this.leading,
    required this.isFilled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: isFilled
            ? null // filled variant: no border needed, accent background is clear
            : Border.all(
                color: Colors.white.withValues(alpha: .12),
                width: 0.5,
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          if (leading != null) ...[
            IconTheme(
              data: IconThemeData(color: fgColor, size: 18),
              child: leading!,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}
