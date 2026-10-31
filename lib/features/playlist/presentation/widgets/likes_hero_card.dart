import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_by_ids_use_case.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/shared/widgets/app_button.dart';

/// Hero banner for the liked songs playlist: one-tap playback and a deck of
/// recent favourite covers.
///
/// Same surface as the Home welcome card: a light accent wash under the
/// glass edge, and no glow, so it sits on the background like the rest.
class LikesHeroCard extends StatefulWidget {
  final Playlist playlist;

  const LikesHeroCard({super.key, required this.playlist});

  @override
  State<LikesHeroCard> createState() => _LikesHeroCardState();
}

class _LikesHeroCardState extends State<LikesHeroCard> {
  List<String> _cachedArtworks = [];
  bool _isLoadingArtworks = true;

  @override
  void initState() {
    super.initState();
    _loadTopArtworks();
  }

  @override
  void didUpdateWidget(covariant LikesHeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playlist.trackIds != widget.playlist.trackIds) {
      _loadTopArtworks();
    }
  }

  Future<void> _loadTopArtworks() async {
    final ids = widget.playlist.trackIds;
    if (ids.isEmpty) {
      if (mounted) {
        setState(() {
          _cachedArtworks = [];
          _isLoadingArtworks = false;
        });
      }
      return;
    }

    final tracks = (await getIt<GetTracksByIdsUseCase>()(
      ids.take(15).toList(),
    )).getOrElse(() => const []);
    final artworks = <String>[];
    final seen = <String>{};

    for (final track in tracks) {
      final path = track.artworkPath;
      if (path != null && path.isNotEmpty && seen.add(path)) {
        artworks.add(path);
        if (artworks.length >= 3) break;
      }
    }

    if (mounted) {
      setState(() {
        _cachedArtworks = artworks;
        _isLoadingArtworks = false;
      });
    }
  }

  Future<void> _playLikes(BuildContext context) async {
    if (widget.playlist.trackIds.isEmpty) return;

    final tracks = (await getIt<GetTracksByIdsUseCase>()(
      widget.playlist.trackIds,
    )).getOrElse(() => const []);

    if (tracks.isNotEmpty && context.mounted) {
      context.read<PlayerBloc>().add(
        PlayTrackRequested(tracks.first, contextQueue: tracks, contextIndex: 0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final glass = GlassTheme.card(context);
    final count = widget.playlist.trackIds.length;
    final l10n = context.l10n;

    return GestureDetector(
      onTap: () => context.pushPlaylist(widget.playlist.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.accent.withValues(alpha: .15),
              colors.accent.withValues(alpha: .05),
            ],
          ),
          border: Border.all(color: glass.border, width: glass.borderWidth),
        ),
        child: Row(
          children: [
            // Left content: badge, title, subtitle & play button
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pill badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.heart, size: 11, color: colors.accent),
                        const SizedBox(width: 4),
                        Text(
                          l10n.likesBadge.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: colors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    l10n.likedSongs,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // Subtitle
                  Text(
                    count == 0
                        ? l10n.likesEmptyBody
                        : l10n.likesSubtitle(l10n.songCount(count)),
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.labelSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),

                  // Action Play button
                  if (count > 0)
                    AppButton.primary(
                      l10n.actionPlay,
                      icon: LucideIcons.play,
                      size: AppButtonSize.small,
                      onPressed: () => _playLikes(context),
                    ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Right side: Stacked cover deck
            _buildArtworkDeck(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildArtworkDeck(AppColors colors) {
    const cardSize = 74.0;

    if (_isLoadingArtworks || _cachedArtworks.isEmpty) {
      return Container(
        width: cardSize + 12,
        height: cardSize + 12,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          color: colors.accent.withValues(alpha: .15),
        ),
        child: Center(
          child: Icon(LucideIcons.heart, color: colors.accent, size: 34),
        ),
      );
    }

    // Stack of up to 3 cards
    final list = _cachedArtworks;
    return SizedBox(
      width: cardSize + 22,
      height: cardSize + 16,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Card 3 (backmost)
          if (list.length >= 3)
            Positioned(
              right: 2,
              child: Transform.rotate(
                angle: 12 * math.pi / 180,
                child: Opacity(
                  opacity: 0.65,
                  child: _DeckCover(path: list[2], size: cardSize - 8),
                ),
              ),
            ),

          // Card 2 (middle)
          if (list.length >= 2)
            Positioned(
              left: 2,
              child: Transform.rotate(
                angle: -10 * math.pi / 180,
                child: Opacity(
                  opacity: 0.85,
                  child: _DeckCover(path: list[1], size: cardSize - 4),
                ),
              ),
            ),

          // Card 1 (frontmost)
          Positioned(
            child: Transform.rotate(
              angle: 1 * math.pi / 180,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _DeckCover(path: list[0], size: cardSize),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.heart,
                        color: colors.accentForeground,
                        size: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One cover of the deck. A soft neutral shadow separates it from the
/// cover below; no border, like every other cover.
class _DeckCover extends StatelessWidget {
  final String path;
  final double size;

  const _DeckCover({required this.path, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: ArtworkImage(path, width: size, height: size),
      ),
    );
  }
}
