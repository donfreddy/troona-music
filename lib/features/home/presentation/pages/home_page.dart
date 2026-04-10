import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/home/presentation/bloc/home_bloc.dart';
import 'package:troona/features/home/presentation/widgets/trending_row.dart';
import 'package:troona/features/library/presentation/widgets/artist_card.dart';
import 'package:troona/features/home/presentation/widgets/playlist_card.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async => context.read<HomeBloc>().add(HomeRefreshRequested()),
        child: CustomScrollView(
          slivers: [
            _HomeAppBar(),
            BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                if (state is HomeLoading) {
                  return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                }
                if (state is HomeLoaded) {
                  final feed = state.feed;
                  return SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: AppSpacing.md),
                      
                      // 1. Recently Played (Songs)
                      _SectionHeader(title: 'Recently Played'),
                      //TrendingRow(tracks: feed.recentlyPlayed),
                      
                      // 2. Your Artists (Artists)
                      _SectionHeader(title: 'Your Artists'),
                      _ArtistCarousel(artists: feed.yourArtists),
                      
                      // 3. New Albums (Albums)
                      _SectionHeader(title: 'New Albums'),
                      _AlbumCarousel(albums: feed.newAlbums),
                      
                      // 4. Your Playlists (Playlists)
                      _SectionHeader(title: 'Your Playlists'),
                      _PlaylistCarousel(playlists: feed.yourPlaylists),
                      
                      const SizedBox(height: 120),
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

class _HomeAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.black.withValues(alpha: .8),
      title: const Text('Troona', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
      actions: [
        GlassIconButton(icon: LucideIcons.settings, onTap: () => context.push(AppRoute.settings)),
        const SizedBox(width: AppSpacing.md),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}

class _ArtistCarousel extends StatelessWidget {
  final List artists;
  const _ArtistCarousel({required this.artists});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        scrollDirection: Axis.horizontal,
        itemCount: artists.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final artist = artists[index];
          return ArtistCard(artist: artist);
        },
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
                SizedBox(width: 130, child: Text(album.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                SizedBox(width: 130, child: Text(album.artist, style: const TextStyle(color: Colors.white30, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlaylistCarousel extends StatelessWidget {
  final List playlists;
  const _PlaylistCarousel({required this.playlists});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        scrollDirection: Axis.horizontal,
        itemCount: playlists.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return PlaylistCard(playlist: playlist);
        },
      ),
    );
  }
}
