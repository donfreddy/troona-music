import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/home/presentation/bloc/home_bloc.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/artist_card.dart';
import 'package:troona/features/playlist/presentation/widgets/playlist_card.dart';
import 'package:troona/shared/widgets/section_heater.dart';
import 'package:troona/shared/widgets/entrance_fader.dart';

Widget _animatedHomeItem(Widget child, int index, {Key? key, double slideY = 0.15, int stepMs = 22}) {
  return EntranceFader.staggered(
    key: key,
    index: index,
    stepMs: stepMs,
    slideY: slideY,
    child: child,
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async => context.read<HomeBloc>().add(HomeRefreshRequested()),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            const SliverToBoxAdapter(child: _HomeHeader()),

            BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                if (state is HomeLoading) {
                  return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                }
                if (state is HomeLoaded) {
                  final feed = state.feed;
                  return SliverMainAxisGroup(
                    slivers: ([
                      if (feed.recentlyPlayed.isNotEmpty) _RecentlyPlayerView(tracks: feed.recentlyPlayed),

                      if (feed.yourArtists.isNotEmpty) _YourArtistsView(artists: feed.yourArtists),

                      if (feed.newAlbums.isNotEmpty) _NewAlbumsView(albums: feed.newAlbums),

                      if (feed.yourPlaylists.isNotEmpty) _YourPlaylistsView(playlists: feed.yourPlaylists),

                      SliverPadding(
                        padding: EdgeInsets.only(
                          bottom: AppSpacing.bottomBlockHeight + MediaQuery.of(context).padding.bottom + AppSpacing.md,
                        ),
                      ),
                    ]),
                  );
                }
                if (state is HomeError) {
                  return SliverFillRemaining(child: Center(child: Text(state.message)));
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _YourArtistsView extends StatelessWidget {
  final List artists; // Assume this matches your feed.yourArtists type

  const _YourArtistsView({required this.artists});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl)),
        SliverToBoxAdapter(
          child: _animatedHomeItem(SectionHeader(title: 'Your Artists', onViewAll: () {}), 0, slideY: 0.05),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: artists.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, i) =>
                  _animatedHomeItem(ArtistCard(artist: artists[i], size: 100), key: ValueKey('artist-${artists[i].id}'), i, slideY: 0.04),
            ),
          ),
        ),
      ],
    );
  }
}

class _NewAlbumsView extends StatelessWidget {
  final List albums;

  const _NewAlbumsView({required this.albums});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl)),
        SliverToBoxAdapter(
          child: _animatedHomeItem(SectionHeader(title: 'New Albums', onViewAll: () {}), 0, slideY: 0.05),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: albums.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, i) => _animatedHomeItem(AlbumCard(album: albums[i], size: 130), key: ValueKey('album-${albums[i].id}'), i, slideY: 0.04),
            ),
          ),
        ),
      ],
    );
  }
}

class _YourPlaylistsView extends StatelessWidget {
  final List playlists;

  const _YourPlaylistsView({required this.playlists});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl)),
        SliverToBoxAdapter(child: _animatedHomeItem(SectionHeader(title: 'Your Playlists'), 0, slideY: 0.05)),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: playlists.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, i) =>
                  _animatedHomeItem(PlaylistCard(playlist: playlists[i], size: 130), key: ValueKey('playlist-${playlists[i].id}'), i, slideY: 0.04),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Adding entry animation to the header as well
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_greeting, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text('Welcome back to your music', style: TextStyle(color: context.colors.labelSecondary, fontSize: 18)),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0, curve: Curves.easeOutCubic),
    );
  }
}

class _RecentlyPlayerView extends StatelessWidget {
  final List<Track> tracks;

  const _RecentlyPlayerView({required this.tracks});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl)),
        SliverToBoxAdapter(child: _animatedHomeItem(SectionHeader(title: 'Recently Played'), 0, slideY: 0.05)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg) + const EdgeInsets.only(top: AppSpacing.xs),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                if (tracks.length >= 2)
                  Row(
                    children: [
                      Expanded(child: _animatedHomeItem(_RecentlyPlayerCard(track: tracks[0]), 1, slideY: 0.03)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: _animatedHomeItem(_RecentlyPlayerCard(track: tracks[1]), 2, slideY: 0.03)),
                    ],
                  ),
                if (tracks.length >= 4) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(child: _animatedHomeItem(_RecentlyPlayerCard(track: tracks[2]), 3, slideY: 0.03)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: _animatedHomeItem(_RecentlyPlayerCard(track: tracks[3]), 4, slideY: 0.03)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.sm)),
      ],
    );
  }
}

class _RecentlyPlayerCard extends StatelessWidget {
  final Track track;

  const _RecentlyPlayerCard({required this.track});

  @override
  Widget build(BuildContext context) {
    final glass = GlassTheme.card(context);

    return Container(
      decoration: BoxDecoration(
        color: glass.fill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: glass.border, width: glass.borderWidth),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            // Artwork
            SizedBox.square(
              dimension: 35,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: track.artworkPath != null
                        ? Image.file(File(track.artworkPath!), width: 50, height: 50, fit: BoxFit.cover)
                        : Container(
                            color: Colors.white.withValues(alpha: .08),
                            child: const Icon(LucideIcons.music, color: Colors.white30),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Info track
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: TextStyle(color: context.colors.labelPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artist,
                    style: TextStyle(color: context.colors.labelSecondary, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
