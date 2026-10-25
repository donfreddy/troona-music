import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/bloc/artist_detail/artist_detail_bloc.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/track_list_tile.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/dynamic_background.dart';
import 'package:troona/shared/widgets/error_view.dart';
import 'package:troona/shared/widgets/glass_button.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';
import 'package:troona/shared/widgets/section_heater.dart';
import 'package:troona/shared/widgets/entrance_fader.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

Widget _animatedArtistItem(
  Widget child,
  int index, {
  Key? key,
  double slideY = 0.15,
  int stepMs = 22,
}) {
  return EntranceFader.staggered(
    key: key,
    index: index,
    stepMs: stepMs,
    slideY: slideY,
    child: child,
  );
}

class ArtistDetailPage extends StatelessWidget {
  final String id;

  const ArtistDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<ArtistDetailBloc, ArtistDetailState>(
        builder: (context, state) {
          final artworkPath = switch (state) {
            ArtistDetailLoaded(:final data) => data.artist.artworkPath,
            _ => null,
          };

          return DynamicBackground(
            artworkPath: artworkPath,
            tone: DynamicBackgroundTone.immersive,
            child: switch (state) {
              ArtistDetailInitial() || ArtistDetailLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              ArtistDetailError(:final message) => ErrorView(
                message: message,
                onRetry: () => context.read<ArtistDetailBloc>().add(
                  ArtistDetailRequested(int.parse(id)),
                ),
              ),
              ArtistDetailLoaded(:final data) => CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _ArtistHeroDelegate(
                      artist: data.artist,
                      tracks: data.topTracks,
                      topPadding: MediaQuery.of(context).padding.top,
                    ),
                  ),
                  if (data.albums.isNotEmpty)
                    _ArtistAlbumsGrid(albums: data.albums),
                  if (data.topTracks.isNotEmpty)
                    _ArtistTopTracksList(tracks: data.topTracks),
                  SliverPadding(
                    padding: EdgeInsets.only(
                      bottom:
                          AppSpacing.miniPlayerHeight +
                          MediaQuery.of(context).padding.bottom +
                          AppSpacing.md,
                    ),
                  ),
                ],
              ),
            },
          );
        },
      ),
    );
  }
}

class _ArtistHeroDelegate extends SliverPersistentHeaderDelegate {
  final Artist artist;
  final List<Track> tracks;
  final double topPadding;

  const _ArtistHeroDelegate({
    required this.artist,
    required this.tracks,
    required this.topPadding,
  });

  static const double _navBarHeight = 44.0;
  static const double _actionsBarHeight = 64.0;
  static const double _expandedExtra = 260.0;

  @override
  double get minExtent => topPadding + _navBarHeight + _actionsBarHeight;

  @override
  double get maxExtent =>
      topPadding + _navBarHeight + _expandedExtra + _actionsBarHeight;

  @override
  bool shouldRebuild(_ArtistHeroDelegate old) =>
      old.artist != artist ||
      old.tracks != tracks ||
      old.topPadding != topPadding;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final collapse = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final bottomScrimOpacity = (1 - shrinkOffset / 24).clamp(0.0, 1.0);
    final currentHeight = (maxExtent - shrinkOffset).clamp(
      minExtent,
      maxExtent,
    );
    final colors = context.colors;

    return RepaintBoundary(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: collapse * 20,
            sigmaY: collapse * 20,
          ),
          child: DecoratedBox(
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
                  // ── Image hero en background (parallax) ────────────────────
                  Positioned(
                    top: -shrinkOffset * 0.4,
                    left: 0,
                    right: 0,
                    bottom: _actionsBarHeight,
                    child: Opacity(
                      opacity: (1 - collapse).clamp(0.0, 1.0),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          artist.artworkPath != null
                              ? ArtworkImage(artist.artworkPath!)
                              : Container(
                                  color: Colors.white.withValues(alpha: .08),
                                  child: const Icon(
                                    LucideIcons.user,
                                    color: Colors.white30,
                                    size: 80,
                                  ),
                                ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(
                                    alpha: .3 * bottomScrimOpacity,
                                  ),
                                  Colors.black.withValues(
                                    alpha: .6 * bottomScrimOpacity,
                                  ),
                                  Colors.black.withValues(
                                    alpha: .85 * bottomScrimOpacity,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Titre + stats grand format ────────────────────────────
                  Positioned(
                    bottom: _actionsBarHeight + AppSpacing.lg,
                    left: AppSpacing.xl,
                    right: AppSpacing.xl,
                    child: Opacity(
                      opacity: (1 - collapse * 1.5).clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, shrinkOffset * 0.2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _animatedArtistItem(
                              Text(
                                artist.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 44,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              0,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            _animatedArtistItem(
                              Text(
                                '${artist.trackCount} songs • ${artist.albumCount} albums',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: .7),
                                  fontSize: 15,
                                ),
                              ),
                              1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Navbar compacte (back + titre + more) ─────────────────
                  Positioned(
                    top: topPadding,
                    left: 0,
                    right: 0,
                    height: _navBarHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: collapse,
                            child: Text(
                              artist.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Positioned(
                            left: 0,
                            child: GlassIconButton(
                              icon: LucideIcons.arrowLeft,
                              onTap: () => context.pop(),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            child: GlassIconButton(
                              icon: LucideIcons.ellipsisVertical,
                              onTap: null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Barre Play/Shuffle dans bottom ────────────────────────
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: _actionsBarHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            child: GlassButton(
                              label: 'Play',
                              leading: const Icon(LucideIcons.play),
                              onTap: () {
                                if (tracks.isNotEmpty) {
                                  context.read<PlayerBloc>().add(
                                    PlayTrackRequested(
                                      tracks[0],
                                      contextQueue: tracks,
                                      contextIndex: 0,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          GlassIconButton(
                            icon: LucideIcons.shuffle,
                            onTap: tracks.isEmpty
                                ? null
                                : () {
                                    context.read<PlayerBloc>().add(
                                      QueueSetRequested(
                                        tracks,
                                        startIndex: 0,
                                      ),
                                    );
                                    context.read<PlayerBloc>().add(
                                      const ShuffleToggleRequested(),
                                    );
                                  },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Albums grid ───────────────────────────────────────────────────────────────
class _ArtistAlbumsGrid extends StatelessWidget {
  final List<Album> albums;
  const _ArtistAlbumsGrid({required this.albums});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              _animatedArtistItem(const SectionHeader(title: 'Albums'), 4),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.lg,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.72,
            ),
            itemCount: albums.length,
            itemBuilder: (context, i) => _animatedArtistItem(
              AlbumCard(
                key: ValueKey('artist-album-${albums[i].id}'),
                album: albums[i],
              ),
              i + 5,
              slideY: 0.04,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl)),
      ],
    );
  }
}

// ── Popular songs ─────────────────────────────────────────────────────────────
class _ArtistTopTracksList extends StatelessWidget {
  final List<Track> tracks;
  const _ArtistTopTracksList({required this.tracks});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              _animatedArtistItem(
                const SectionHeader(title: 'Popular Songs'),
                5,
              ),
            ],
          ),
        ),
        SliverList.separated(
          itemCount: tracks.length,
          separatorBuilder: (_, _) =>
              Divider(height: 0.5, indent: 72, color: context.colors.separator),
          itemBuilder: (context, i) => _animatedArtistItem(
            TrackListTile(
              key: ValueKey('track-${tracks[i].id}'),
              track: tracks[i],
              onTap: () => context.read<PlayerBloc>().add(
                PlayTrackRequested(
                  tracks[i],
                  contextQueue: tracks,
                  contextIndex: i,
                ),
              ),
            ),
            i + 6,
          ),
        ),
      ],
    );
  }
}
