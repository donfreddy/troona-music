import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/home/presentation/bloc/home_bloc.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/artist_card.dart';
import 'package:troona/features/playlist/presentation/widgets/playlist_card.dart';
import 'package:troona/shared/widgets/section_heater.dart';

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
                      // 1. Recently Played (Songs)
                      if (feed.recentlyPlayed.isNotEmpty) ...[
                        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl)),
                        SliverToBoxAdapter(child: SectionHeader(title: 'Recently Played')),
                        _RecentlyPlayerView(tracks: feed.recentlyPlayed),
                        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.sm)),
                      ],

                      // 2. Your Artists (Artists)
                      if (feed.yourArtists.isNotEmpty) ...[
                        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl)),
                        SliverToBoxAdapter(
                          child: SectionHeader(title: 'Your Artists', onViewAll: () {}),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 140,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              itemCount: feed.yourArtists.length,
                              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
                              itemBuilder: (context, i) => ArtistCard(artist: feed.yourArtists[i], size: 100),
                            ),
                          ),
                        ),
                      ],

                      // 3. New Albums (Albums)
                      if (feed.newAlbums.isNotEmpty) ...[
                        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl)),
                        SliverToBoxAdapter(
                          child: SectionHeader(title: 'New Albums', onViewAll: () {}),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 180,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              itemCount: feed.newAlbums.length,
                              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
                              itemBuilder: (context, i) => AlbumCard(album: feed.newAlbums[i], size: 130),
                            ),
                          ),
                        ),
                      ],

                      // // 4. Your Playlists (Playlists)
                      if (feed.yourPlaylists.isNotEmpty) ...[
                        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl)),
                        SliverToBoxAdapter(child: SectionHeader(title: 'Your Playlists')),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 180,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              itemCount: feed.yourPlaylists.length,
                              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
                              itemBuilder: (context, i) => PlaylistCard(playlist: feed.yourPlaylists[i], size: 130),
                            ),
                          ),
                        ),
                      ],

                      // SectionHeader(title: 'Your Playlists'),
                      // _PlaylistCarousel(playlists: feed.yourPlaylists),
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good Evening', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text('Welcome back to your music', style: TextStyle(color: context.colors.labelSecondary, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

class _RecentlyPlayerView extends StatelessWidget {
  final List<Track> tracks;

  const _RecentlyPlayerView({required this.tracks});

  @override
  Widget build(BuildContext context) {
    // final isActive = context.select<PlayerBloc, bool>(
    //   (b) =>
    //       b.state is PlayerActive &&
    //       (b.state as PlayerActive).currentTrack.id == widget.track.id,
    // );

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg) + const EdgeInsets.only(top: AppSpacing.xs),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _RecentlyPlayerCard(track: tracks[0])),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _RecentlyPlayerCard(track: tracks[1])),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: _RecentlyPlayerCard(track: tracks[2])),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _RecentlyPlayerCard(track: tracks[3])),
              ],
            ),
          ],
        ),
      ),
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

                  // if (isActive)
                  //   Positioned.fill(
                  //     child: DecoratedBox(
                  //       decoration: BoxDecoration(
                  //         color: Colors.black.withValues(alpha: .4),
                  //         borderRadius: BorderRadius.circular(8),
                  //       ),
                  //       child: Icon(LucideIcons.music2, color: context.colors.labelPrimary, size: 20),
                  //     ),
                  //   ),
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
                    style: TextStyle(
                      color: context.colors.labelPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      //fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
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

class _AlbumCarousel extends StatelessWidget {
  final List albums;
  const _AlbumCarousel({required this.albums});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        scrollDirection: Axis.horizontal,
        itemCount: albums.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final album = albums[index];
          return InkWell(
            onTap: () => context.pushNamed(AppRoute.albumDetail, pathParameters: {'id': album.id.toString()}),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(LucideIcons.disc, color: Colors.white24, size: 48),
                ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  width: 130,
                  child: Text(
                    album.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: Text(
                    album.artist,
                    style: const TextStyle(color: Colors.white30, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
