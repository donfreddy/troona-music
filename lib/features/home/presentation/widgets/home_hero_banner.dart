import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

/// Hero banner at the top of the home page.
///
/// Two modes:
/// - **Welcome** (Cold Start): elegant invite to scan the library.
/// - **Continue Listening** (Warm State): last played track with play CTA.
class HomeHeroBanner extends StatelessWidget {
  /// Null when in Cold Start mode.
  final Track? lastPlayed;
  final VoidCallback? onContinue;
  final VoidCallback? onScanLibrary;

  const HomeHeroBanner({
    super.key,
    this.lastPlayed,
    this.onContinue,
    this.onScanLibrary,
  });

  bool get _isColdStart => lastPlayed == null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: _isColdStart ? _buildWelcome(context) : _buildContinue(context),
    );
  }

  // ── Cold Start: Welcome Card ────────────────────────────────────────────

  Widget _buildWelcome(BuildContext context) {
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
            child: Icon(
              LucideIcons.music,
              color: context.colors.accent,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Your music, offline.',
            style: TextStyle(
              color: context.colors.labelPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Always.',
            style: TextStyle(
              color: context.colors.labelSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Scan CTA
          GestureDetector(
            onTap: onScanLibrary,
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
                    LucideIcons.search,
                    color: context.colors.accentForeground,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Scan Library',
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

  // ── Warm State: Continue Listening ──────────────────────────────────────

  Widget _buildContinue(BuildContext context) {
    final track = lastPlayed!;
    final glass = GlassTheme.card(context);

    return GestureDetector(
      onTap: onContinue,
      child: Container(
        width: double.infinity,
        height: 100,
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
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: SizedBox.square(
                      dimension: 68,
                      child: track.artworkPath != null
                          ? ArtworkImage(
                              track.artworkPath!,
                              width: 68,
                              height: 68,
                            )
                          : Container(
                              color: Colors.white.withValues(alpha: .08),
                              child: const Icon(
                                LucideIcons.music,
                                color: Colors.white30,
                                size: 28,
                              ),
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
                          'Continue listening',
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
                          track.artist,
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
                      LucideIcons.play,
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
