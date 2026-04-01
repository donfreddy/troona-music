import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/home/domain/entities/home_feed.dart';
import 'package:troona/features/home/presentation/bloc/home_bloc.dart';
import 'package:troona/shared/widgets/empty_state.dart';
import 'package:troona/shared/widgets/error_view.dart';
import 'package:troona/features/home/presentation/widgets/playlist_card.dart';
import 'package:troona/features/home/presentation/widgets/shimmer_row.dart';
import 'package:troona/features/home/presentation/widgets/trending_row.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/dynamic_background.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const HomeFeedRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Fond gradient violet dynamique ─────────────
          // Reprend la couleur dominante du track en cours
          BlocSelector<PlayerBloc, PlayerState, String?>(
            selector: (s) =>
                s is PlayerActive ? s.currentTrack.artworkPath : null,
            builder: (_, artworkPath) => DynamicBackground(
              artworkPath: artworkPath,
              child: const SizedBox.expand(),
            ),
          ),

          // ── Contenu scrollable ──────────────────────────
          BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) => CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // Safe area top + avatar + cloche
                SliverToBoxAdapter(child: _HomeHeader()),

                // Corps selon état
                switch (state) {
                  HomeLoading() || HomeInitial() => SliverList.builder(
                    itemCount: 8,
                    itemBuilder: (_, _) => const ShimmerRow(),
                  ),
                  HomeLoaded(:final feed, :final totalTracks) => _HomeFeedBody(feed: feed, totalTracks: totalTracks),
                  HomeError(:final message) => SliverFillRemaining(
                    child: ErrorView(
                      message: message,
                      onRetry: () => context.read<HomeBloc>().add(
                        const HomeRefreshRequested(),
                      ),
                    ),
                  ),
                },

                // Padding pour la BottomNavBar
                const SliverPadding(
                  padding: EdgeInsets.only(
                    bottom: AppSpacing.miniPlayerHeight + AppSpacing.xl3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Avatar utilisateur
            GestureDetector(
              onTap: () => context.go('/settings'),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .25),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.person_fill,
                  color: Colors.white70,
                  size: 22,
                ),
              ),
            ),

            // Cloche notifications
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .15),
                  width: 0.5,
                ),
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {},
                child: const Icon(
                  EvaIcons.bellOutline,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeFeedBody extends StatelessWidget {
  final HomeFeed feed;
  final int totalTracks;

  const _HomeFeedBody({required this.feed, required this.totalTracks});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        // ── Section Popular Playlists ──────────────────────
        _SectionHeader(
          title: 'Popular Playlists',
          onViewAll: () => context.go('/playlists'),
        ),

        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: feed.popularPlaylists.isEmpty
                ? const EmptyState(
                    message: 'Aucune playlist trouvée',
                    icon: Icons.playlist_play,
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    itemCount: feed.popularPlaylists.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (context, i) =>
                        PlaylistCard(playlist: feed.popularPlaylists[i]),
                  ),
          ),
        ),

        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl)),

        // ── Section Trending Now ──────────────────────────
        _SectionHeader(
          title: 'Trending Now ${feed.trendingTracks.length}',
          onViewAll: () => context.go('/library'),
        ),

        SliverList.separated(
          itemCount: feed.trendingTracks.length,
          separatorBuilder: (_, _) => Divider(
            height: 0.5,
            indent: 74,
            color: Colors.white.withValues(alpha: .08),
          ),
          itemBuilder: (context, i) => TrendingRow(
            track: feed.trendingTracks[i],
            rank: i + 1,
            onTap: () => context.read<PlayerBloc>().add(
              PlayTrackRequested(
                feed.trendingTracks[i],
                contextQueue: feed.trendingTracks,
                contextIndex: i,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section header ────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;
  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            GestureDetector(
              onTap: onViewAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .15),
                    width: 0.5,
                  ),
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
