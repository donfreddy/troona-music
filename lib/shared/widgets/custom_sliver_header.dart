import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';

/// Large title iOS-style : grand titre en haut, qui se réduit
/// en navigation bar compacte au scroll, avec blur glassmorphism.
class CustomSliverHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final Widget? bottom; // search bar, segment control...
  final double expandedHeight;

  const CustomSliverHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.bottom,
    this.expandedHeight = 140,
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
  final double topPadding;

  const _LargeTitleDelegate({
    required this.title,
    required this.actions,
    required this.expandedHeight,
    required this.topPadding,
    this.bottom,
  });

  // Hauteur minimale = compact nav bar + safe area
  @override
  double get minExtent => topPadding + 44 + (bottom != null ? 52 : 0);

  // Hauteur maximale = large title déplié
  @override
  double get maxExtent =>
      topPadding + expandedHeight + (bottom != null ? 52 : 0);

  @override
  bool shouldRebuild(_LargeTitleDelegate old) =>
      old.title != title ||
      old.expandedHeight != expandedHeight ||
      old.bottom != bottom;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // 0.0 = complètement déplié, 1.0 = complètement replié
    final collapse = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final colors = context.colors;
    final theme = Theme.of(context);

    return RepaintBoundary(
      child: ClipRect(
        child: BackdropFilter(
          // Le blur s'intensifie au fil du collapse
          filter: ImageFilter.blur(
            sigmaX: collapse * 20,
            sigmaY: collapse * 20,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              // Fond transparent quand déplié, glassmorphism quand replié
              color: Color.lerp(Colors.transparent, colors.glassFill, collapse),
              border: Border(
                bottom: BorderSide(
                  color: colors.separator.withValues(alpha: collapse),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: topPadding),

                // ── Compact nav bar (toujours présente) ──────────
                SizedBox(
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Titre compact — apparaît en fadant au collapse
                      Opacity(
                        opacity: collapse,
                        child: Text(
                          title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colors.labelPrimary,
                          ),
                        ),
                      ),

                      // Actions à droite
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

                // ── Large title — disparaît en fadant au collapse ──
                Padding(
                  padding: EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom: AppSpacing.sm,
                  ),
                  child: Opacity(
                    opacity: (1 - collapse * 2).clamp(0.0, 1.0),
                    child: Transform.translate(
                      // Glisse vers le haut en se repliant
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: bottom!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
