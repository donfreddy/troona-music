import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

/// Hero Banner for the "Titres likés" (Coups de cœur) playlist.
///
/// Features a dark carmine/ruby glass aesthetic, direct one-tap playback,
/// and an overlapping 3-card artwork deck displaying recent favorite covers.
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

    final isar = getIt<IsarLibraryDataSource>();
    final artworks = <String>[];
    final seen = <String>{};

    for (final id in ids.take(15)) {
      final path = await isar.getArtworkPathById(id);
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

    final isar = getIt<IsarLibraryDataSource>();
    final models = await isar.getTracksByIds(widget.playlist.trackIds);
    final tracks = models.map((m) => m.toEntity()).toList();

    if (tracks.isNotEmpty && context.mounted) {
      context.read<PlayerBloc>().add(
        PlayTrackRequested(tracks.first, contextQueue: tracks, contextIndex: 0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final count = widget.playlist.trackIds.length;
    final countLabel = count == 1 ? '1 morceau' : '$count morceaux';

    return GestureDetector(
      onTap: () => context.pushPlaylist(widget.playlist.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B122E),
              Color(0xFF100B1D),
              Color(0xFF07050D),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFB79CFF).withValues(alpha: 0.28),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB79CFF).withValues(alpha: 0.16),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
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
                      color: const Color(0xFFB79CFF).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFB79CFF).withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.heart,
                          size: 11,
                          color: Color(0xFFB79CFF),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'COUPS DE CŒUR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: Color(0xFFD8C7FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Title
                  const Text(
                    'Titres likés',
                    style: TextStyle(
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
                        ? 'Aucun titre favori pour le moment'
                        : '$countLabel • Vos favoris réunis',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),

                  // Action Play button
                  if (count > 0)
                    InkWell(
                      onTap: () => _playLikes(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB79CFF),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFB79CFF,
                              ).withValues(alpha: 0.40),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.play,
                              size: 14,
                              color: Color(0xFF12081F),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Écouter',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF12081F),
                              ),
                            ),
                          ],
                        ),
                      ),
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
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB79CFF), Color(0xFF5A3FA3)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB79CFF).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Icon(LucideIcons.heart, color: Color(0xFF12081F), size: 34),
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
                  _DeckCover(
                    path: list[0],
                    size: cardSize,
                    hasGlow: true,
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFB79CFF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.heart,
                        color: Color(0xFF12081F),
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

class _DeckCover extends StatelessWidget {
  final String path;
  final double size;
  final bool hasGlow;

  const _DeckCover({
    required this.path,
    required this.size,
    this.hasGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: hasGlow
                ? const Color(0xFFB79CFF).withValues(alpha: 0.32)
                : Colors.black.withValues(alpha: 0.4),
            blurRadius: hasGlow ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: ArtworkImage(path, width: size, height: size),
      ),
    );
  }
}
