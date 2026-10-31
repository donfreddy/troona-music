import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

/// Hero banner at the top of the home page.
///
/// Three modes:
/// - **Empty**: no music on the device; explains how to add some.
/// - **Fresh**: music but no plays yet; offers a shuffle of everything.
/// - **Continue**: the last played song, one tap to resume.
class HomeHeroBanner extends StatelessWidget {
  /// Null until something has been played.
  final Track? lastPlayed;
  final int totalTracks;
  final VoidCallback? onContinue;
  final VoidCallback? onShuffleAll;
  final VoidCallback? onScanAgain;

  const HomeHeroBanner({
    super.key,
    this.lastPlayed,
    required this.totalTracks,
    this.onContinue,
    this.onShuffleAll,
    this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: switch ((lastPlayed, totalTracks)) {
        (_, 0) => _buildWelcome(
          context,
          icon: AppIcons.track,
          title: l10n.homeEmptyTitle,
          body: l10n.homeEmptyBody,
          ctaIcon: AppIcons.refresh,
          ctaLabel: l10n.libraryScanAgain,
          onTap: onScanAgain,
        ),
        (null, _) => _buildWelcome(
          context,
          icon: AppIcons.listen,
          title: l10n.homeFreshTitle,
          body: l10n.homeSongsReady(totalTracks),
          ctaIcon: AppIcons.shuffle,
          ctaLabel: l10n.libraryShuffleAll,
          onTap: onShuffleAll,
        ),
        _ => _buildContinue(context),
      },
    );
  }

  // ── Empty and fresh: invitation card ────────────────────────────────────

  Widget _buildWelcome(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    required IconData ctaIcon,
    required String ctaLabel,
    required VoidCallback? onTap,
  }) {
    final glass = GlassTheme.card(context);
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.colors.accent.withValues(alpha: .15),
                context.colors.accent.withValues(alpha: .05),
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: glass.border, width: glass.borderWidth),
          ),
          child: Column(
            children: [
              // Music icon with subtle glow
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.accent.withValues(alpha: .12),
                ),
                child: Icon(icon, color: context.colors.accent, size: 28),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.labelPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.labelSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.accent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        ctaIcon,
                        color: context.colors.accentForeground,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        ctaLabel,
                        style: TextStyle(
                          color: context.colors.accentForeground,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }

  // ── Continue ────────────────────────────────────────────────────────────

  Widget _buildContinue(BuildContext context) {
    final track = lastPlayed!;
    final glass = GlassTheme.card(context);

    return GestureDetector(
          onTap: onContinue,
          child: Container(
            width: double.infinity,
            // At least the design height; taller when a large font needs it.
            constraints: const BoxConstraints(minHeight: 100),
            decoration: BoxDecoration(
              color: glass.fill,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(color: glass.border, width: glass.borderWidth),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Background artwork blurred overlay
                if (track.artworkPath != null)
                  Positioned.fill(
                    child: ShaderMask(
                      shaderCallback: (rect) => LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: .3),
                        ],
                      ).createShader(rect),
                      blendMode: BlendMode.dstIn,
                      child: ArtworkImage(
                        track.artworkPath!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      // Artwork thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        child: SizedBox.square(
                          dimension: 68,
                          child: ArtworkImage(
                            track.artworkPath,
                            width: 68,
                            height: 68,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      // Track info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.l10n.homeJumpBackIn,
                              style: TextStyle(
                                color: context.colors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              track.title,
                              style: TextStyle(
                                color: context.colors.labelPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              context.artistName(track.artist),
                              style: TextStyle(
                                color: context.colors.labelSecondary,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Play button
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.colors.accent,
                        ),
                        child: Icon(
                          AppIcons.play,
                          color: context.colors.accentForeground,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
  }
}
