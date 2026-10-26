import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/entrance_fader.dart';

/// A horizontal row of quick-access action chips (Spotify-style).
///
/// - **Likes**: navigates to the likes playlist with a badge count.
/// - **Shuffle All**: shuffles the entire library.
/// - **Recently Added**: jumps to library sorted by date.
class QuickAccessRow extends StatelessWidget {
  final int likesCount;
  final int totalTracks;

  const QuickAccessRow({
    super.key,
    required this.likesCount,
    required this.totalTracks,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = totalTracks > 0;
    final opacity = isActive ? 1.0 : 0.45;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: EntranceFader.staggered(
              index: 0,
              child: _QuickChip(
                icon: LucideIcons.heart,
                label: 'Likes',
                badge: likesCount > 0 ? likesCount.toString() : null,
                opacity: opacity,
                onTap: isActive
                    ? () {
                        context.go(AppRoute.playlists);
                      }
                    : null,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: EntranceFader.staggered(
              index: 1,
              child: _QuickChip(
                icon: LucideIcons.shuffle,
                label: 'Shuffle',
                opacity: opacity,
                onTap: isActive
                    ? () {
                        final libraryState =
                            context.read<LibraryBloc>().state;
                        if (libraryState is LibraryLoaded &&
                            libraryState.allTracks.isNotEmpty) {
                          final tracks = List<Track>.of(libraryState.allTracks)
                            ..shuffle();
                          context.read<PlayerBloc>().add(
                            PlayTrackRequested(
                              tracks.first,
                              contextQueue: tracks,
                              contextIndex: 0,
                            ),
                          );
                        }
                      }
                    : null,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: EntranceFader.staggered(
              index: 2,
              child: _QuickChip(
                icon: LucideIcons.clock,
                label: 'Recent',
                opacity: opacity,
                onTap: isActive
                    ? () {
                        context.read<LibraryBloc>().add(
                          const LibraryFilterChanged(LibraryFilter.tracks),
                        );
                        context.go(AppRoute.library);
                      }
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final double opacity;
  final VoidCallback? onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    this.badge,
    this.opacity = 1.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glass = GlassTheme.card(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: glass.fill,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: glass.border, width: glass.borderWidth),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: context.colors.accent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: context.colors.labelPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.accent.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: context.colors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
