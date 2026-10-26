import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';

class TrackShimmer extends StatelessWidget {
  const TrackShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Artwork placeholder
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Title & Subtitle placeholders
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 140,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .07),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 90,
                      height: 11,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .04),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              // Trailing action placeholder
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .04),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: const Duration(milliseconds: 1400),
          color: Colors.white.withValues(alpha: .08),
        );
  }
}
