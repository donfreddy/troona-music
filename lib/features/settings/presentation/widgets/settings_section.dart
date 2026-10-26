import 'package:flutter/material.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/shared/widgets/glass_card.dart';

/// Grouped Apple Settings style section.
///
/// Wraps its child rows in a translucent [GlassCard] with fine hairline dividers
/// indented to align with row labels.
class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final String? footer;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Header Label ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xs + 2,
          ),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: colors.accent,
            ),
          ),
        ),

        // ── Grouped Glass Card ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: GlassCard(
            config: GlassTheme.card(
              context,
            ).copyWith(blurSigma: 0, padding: EdgeInsets.zero),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              child: Column(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 0.5,
                        indent:
                            58, // Align with text after the 32px badge + padding
                        endIndent: 16,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
        ),

        // ── Optional Section Footer / Caption ───────────────────────────────
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs + 2,
              AppSpacing.lg,
              0,
            ),
            child: Text(
              footer!,
              style: TextStyle(
                fontSize: 12,
                color: colors.labelTertiary,
                height: 1.35,
              ),
            ),
          ),
      ],
    );
  }
}
