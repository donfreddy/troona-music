import 'package:flutter/material.dart';
import 'package:troona/core/theme/components/blur_budget.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/theme/components/glass_filter.dart';

/// The app's single way to open a modal bottom sheet.
///
/// Wraps [showModalBottomSheet] with a transparent background and a
/// [GlassBottomSheet] body so callers only provide their content:
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
/// The sheet opens above the mini player and the tab bar; with
/// [useRootNavigator] false it would live in the branch's navigator, under them.
///
/// The glass comes from [GlassTheme.aboveGlass] read from [context]: a blur
/// on high-tier devices, opaque elsewhere, over Now Playing and over another
/// sheet. [quality] overrides it.
///
/// A sheet that can grow to the top of the screen sets [useSafeArea], so it
/// stops below the status bar.
///
/// [padding] replaces the default content padding (see [GlassBottomSheet]).
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool isScrollControlled = false,
  bool useRootNavigator = true,
  bool useSafeArea = false,
  GlassQuality? quality,
  EdgeInsetsGeometry? padding,
}) {
  final resolved = quality ?? GlassTheme.aboveGlass(context);
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .35),
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    useSafeArea: useSafeArea,
    // A sheet opened from this one would be one blur too many: [builder]
    // gets a context below the mark.
    builder: (_) => BlurBudgetSpent(
      child: GlassBottomSheet(
        quality: resolved,
        padding: padding,
        child: Builder(builder: builder),
      ),
    ),
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

  /// Padding around [child]. Defaults to [AppSpacing.lg] on the sides and
  /// below, plus the bottom inset. A child that handles the bottom inset
  /// itself (a list scrolling under it) passes [EdgeInsets.zero].
  final EdgeInsetsGeometry? padding;

  /// Overrides the user's glass quality; [GlassQuality.off] is opaque.
  final GlassQuality? quality;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.showHandle = true,
    this.padding,
    this.quality,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = GlassTheme.sheet(context, quality: quality);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final content = _SheetContent(
      config: cfg,
      showHandle: showHandle,
      padding:
          padding ??
          EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg + bottomInset,
          ),
      child: child,
    );

    if (cfg.blurSigma == 0) {
      return ClipRRect(borderRadius: cfg.borderRadius, child: content);
    }

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: cfg.borderRadius,
        child: BackdropFilter(
          filter: GlassFilter.of(cfg.blurSigma, saturation: cfg.saturation),
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
  final EdgeInsetsGeometry padding;

  const _SheetContent({
    required this.config,
    required this.child,
    required this.showHandle,
    required this.padding,
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
            child: Padding(padding: padding, child: child),
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
