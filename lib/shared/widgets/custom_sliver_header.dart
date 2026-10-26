import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';

/// iOS-style large title: a big title at the top that shrinks
/// into a compact navigation bar on scroll, with a glass blur.
class CustomSliverHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final Widget? bottom; // search bar, segment control...
  final double expandedHeight;
  final double bottomHeight;

  const CustomSliverHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.bottom,
    this.expandedHeight = 140,
    this.bottomHeight = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _LargeTitleDelegate(
        title: title,
        actions: actions,
        bottom: bottom,
        expandedHeight: expandedHeight,
        bottomHeight: bottom != null ? bottomHeight : 0,
        topPadding: MediaQuery.of(context).padding.top,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────

class _LargeTitleDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final List<Widget> actions;
  final Widget? bottom;
  final double expandedHeight;
  final double bottomHeight;
  final double topPadding;

  const _LargeTitleDelegate({
    required this.title,
    required this.actions,
    required this.expandedHeight,
    required this.bottomHeight,
    required this.topPadding,
    this.bottom,
  });

  static const _navBarHeight = 44.0;

  // Hauteur minimale = compact nav bar + safe area
  @override
  double get minExtent => topPadding + _navBarHeight + bottomHeight;

  // Maximum height: large title expanded
  @override
  double get maxExtent => topPadding + expandedHeight + bottomHeight;

  @override
  bool shouldRebuild(_LargeTitleDelegate old) =>
      old.title != title ||
      old.expandedHeight != expandedHeight ||
      old.bottomHeight != bottomHeight ||
      old.bottom != bottom;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // 0.0 fully expanded, 1.0 fully collapsed
    final collapse = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final currentHeight = (maxExtent - shrinkOffset).clamp(
      minExtent,
      maxExtent,
    );
    final colors = context.colors;
    final theme = Theme.of(context);
    final largeTitleBottom = bottomHeight + AppSpacing.sm;

    final blurSigma = GlassTheme.card(context).blurSigma * collapse;

    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: Color.lerp(Colors.transparent, colors.glassFill, collapse),
        border: Border(
          bottom: BorderSide(
            color: colors.separator.withValues(alpha: collapse),
            width: 0.5,
          ),
        ),
      ),
      child: SizedBox(
        height: currentHeight,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // ── Compact nav bar (always present) ──────────
            Positioned(
              top: topPadding,
              left: 0,
              right: 0,
              height: _navBarHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Compact title: fades in on collapse
                  Opacity(
                    opacity: collapse,
                    child: Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colors.labelPrimary,
                      ),
                    ),
                  ),

                  // Trailing actions
                  if (actions.isNotEmpty)
                    Positioned(
                      right: AppSpacing.lg,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions,
                      ),
                    ),
                ],
              ),
            ),

            // ── Large title: fades out on collapse ──
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: largeTitleBottom,
              child: Opacity(
                opacity: (1 - collapse * 2).clamp(0.0, 1.0),
                child: Transform.translate(
                  // Slides up while collapsing
                  offset: Offset(0, -shrinkOffset * 0.3),
                  child: Text(
                    title,
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: colors.labelPrimary,
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom (search bar, segment control) ─────────
            if (bottom != null)
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: 0,
                height: bottomHeight,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: bottom!,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return RepaintBoundary(
      child: ClipRect(
        child: blurSigma > 0
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: content,
              )
            : content,
      ),
    );
  }
}
