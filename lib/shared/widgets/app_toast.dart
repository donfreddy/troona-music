import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/shared/widgets/toast_anchor.dart';

/// The app's single transient message: a pill just above the bottom bar
/// (see [ToastAnchor]), or near the bottom edge when there is none.
///
/// One at a time; a new toast replaces the current one. Flat fill, no blur:
/// it can show over any page, Now Playing included, without breaking the
/// blur budget.
abstract final class AppToast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    showOn(
      overlay,
      message,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Same as [show], on an overlay captured earlier. Use it when the calling
  /// route is about to close, since its context can no longer find one.
  static void showOn(
    OverlayState overlay,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!overlay.mounted) return;
    dismiss();

    final view = _ToastView(
      message: message,
      actionLabel: actionLabel,
      onAction: onAction == null
          ? null
          : () {
              dismiss();
              onAction();
            },
    );
    final entry = OverlayEntry(
      builder: (context) => ValueListenableBuilder<double?>(
        valueListenable: ToastAnchor.top,
        builder: (context, barTop, child) => AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: bottomOffset(
            screenHeight: MediaQuery.sizeOf(context).height,
            safeBottom: MediaQuery.paddingOf(context).bottom,
            barTop: barTop,
          ),
          child: child!,
        ),
        child: view,
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(duration, dismiss);
  }

  /// Space between the toast and the bar, or the bottom edge.
  static const gap = 8.0;

  /// Distance from the screen's bottom edge to the toast's: just above the
  /// bar's top edge, or above the system inset when no bar is mounted.
  @visibleForTesting
  static double bottomOffset({
    required double screenHeight,
    required double safeBottom,
    required double? barTop,
  }) => barTop == null
      ? safeBottom + AppSpacing.md + gap
      : screenHeight - barTop + gap;

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _ToastView extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ToastView({required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.bgSecondary.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.labelPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  child: Text(
                    actionLabel!,
                    style: TextStyle(
                      color: colors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 180.ms).slideY(begin: 0.3, end: 0);
  }
}
