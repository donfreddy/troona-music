import 'package:flutter/material.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/theme/components/glass_filter.dart';

/// Shows a glass-styled modal bottom sheet.
///
/// Wraps [showModalBottomSheet] with a transparent barrier and a [GlassBottomSheet]
/// body so callers only need to provide their content:
///
/// ```dart
/// showGlassBottomSheet(
///   context: context,
///   builder: (ctx) => const QueuePanel(),
/// );
/// ```
///
/// Set [isScrollControlled] to true when the child may be taller than half the
/// screen (e.g. a full-height queue list).
///
/// Opened from a shell page, the sheet lives in that branch's navigator, under
/// the mini player and the tab bar: [useRootNavigator] puts it above them.
/// Over glass that already blurs, pass [GlassQuality.off] as [quality] to keep
/// to two blurs on screen.
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  GlassQuality? quality,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .50),
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    builder: (ctx) => GlassBottomSheet(quality: quality, child: builder(ctx)),
  );
}

/// A glass-styled bottom sheet surface.
///
/// Renders [GlassTheme.sheet] fill, border, and, when [GlassConfig.blurSigma]
/// is non-zero, a [BackdropFilter] wrapped in [RepaintBoundary].
///
/// The sheet expands to its child's intrinsic height plus [MediaQueryData.padding]
/// bottom inset (home-indicator clearance).  For scrollable content combine with
/// [DraggableScrollableSheet] or pass [isScrollControlled] true to
/// [showGlassBottomSheet].
///
/// A drag handle is shown at the top when [showHandle] is true (default).
class GlassBottomSheet extends StatelessWidget {
  final Widget child;

  /// Whether to show the drag-indicator pill at the top of the sheet.
  final bool showHandle;

  /// Horizontal padding applied to [child].  Defaults to [AppSpacing.lg].
  final double horizontalPadding;

  /// Overrides the user's glass quality; [GlassQuality.off] is opaque.
  final GlassQuality? quality;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.showHandle = true,
    this.horizontalPadding = AppSpacing.lg,
    this.quality,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = GlassTheme.sheet(context, quality: quality);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final content = _SheetContent(
      config: cfg,
      showHandle: showHandle,
      horizontalPadding: horizontalPadding,
      bottomInset: bottomInset,
      child: child,
    );

    if (cfg.blurSigma == 0) {
      return ClipRRect(borderRadius: cfg.borderRadius, child: content);
    }

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: cfg.borderRadius,
        child: BackdropFilter(
          filter: GlassFilter.of(cfg.blurSigma),
          child: content,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Decoration + layout wrapper for the sheet body.
///
/// Separated from [GlassBottomSheet] so the decoration is applied inside
/// [BackdropFilter] (the blur samples from what is behind the decoration,
/// not from the decorated surface itself).
class _SheetContent extends StatelessWidget {
  final GlassConfig config;
  final Widget child;
  final bool showHandle;
  final double horizontalPadding;
  final double bottomInset;

  const _SheetContent({
    required this.config,
    required this.child,
    required this.showHandle,
    required this.horizontalPadding,
    required this.bottomInset,
  });

  @override
  Widget build(BuildContext context) {
    // One colour on every drawn side: Flutter cannot paint a rounded border
    // whose sides differ in colour. The bottom edge bleeds to the screen.
    final side = BorderSide(color: config.border, width: config.borderWidth);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: config.fill,
        borderRadius: config.borderRadius,
        border: Border(top: side, left: side, right: side),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHandle) ...[
            const SizedBox(height: AppSpacing.sm),
            const _DragHandle(),
            const SizedBox(height: AppSpacing.sm),
          ] else
            SizedBox(height: config.padding.top),
          Flexible(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                AppSpacing.lg + bottomInset,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Standard iOS-style drag-indicator pill.
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          // ~30 % white: visible on both dark glass and light glass surfaces.
          color: Colors.white.withValues(alpha: .30),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
