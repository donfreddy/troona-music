import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/home/presentation/bloc/home_bloc.dart';
import 'package:troona/features/home/presentation/widgets/hidden_gems_row.dart';
import 'package:troona/features/home/presentation/widgets/home_hero_banner.dart';
import 'package:troona/features/home/presentation/widgets/quick_access_row.dart';
import 'package:troona/features/home/presentation/widgets/recently_played_grid.dart';
import 'package:troona/features/home/presentation/widgets/top_weekly_row.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/artist_card.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/playlist/presentation/widgets/playlist_card.dart';
import 'package:troona/shared/widgets/entrance_fader.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';
import 'package:troona/shared/widgets/section_heater.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomePage — Troona's adaptive home feed
// ─────────────────────────────────────────────────────────────────────────────
//
// Displays two distinct visual states:
// • Cold Start  — elegant welcome + scan CTA when no plays exist
// • Warm State  — intelligent feed driven by local listening stats
// ─────────────────────────────────────────────────────────────────────────────

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async =>
            context.read<HomeBloc>().add(HomeRefreshRequested()),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            const SliverToBoxAdapter(child: _HomeHeader()),
            BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                if (state is HomeLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (state is HomeLoaded) {
                  return _HomeBody(state: state);
                }
                if (state is HomeError) {
                  return SliverFillRemaining(
                    child: Center(child: Text(state.message)),
                  );
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

// ─────────────────────────────────────────────────────────────────────────────
// Home Body — assembles all sections based on feed state
// ─────────────────────────────────────────────────────────────────────────────

class _HomeBody extends StatelessWidget {
  final HomeLoaded state;

  const _HomeBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final feed = state.feed;
    final isColdStart = feed.isColdStart;

    return SliverMainAxisGroup(
      slivers: [
        // ── Hero Banner ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: HomeHeroBanner(
            lastPlayed: isColdStart ? null : feed.recentlyPlayed.firstOrNull,
            onContinue: isColdStart
                ? null
                : () {
                    final track = feed.recentlyPlayed.first;
                    context.read<PlayerBloc>().add(
                      PlayTrackRequested(
                        track,
                        contextQueue: feed.recentlyPlayed,
                        contextIndex: 0,
                      ),
                    );
                  },
            onScanLibrary: () {
              context.read<LibraryBloc>().add(LibraryScanRequested());
              context.go(AppRoute.library);
            },
          ),
        ),
        const _SectionGap(),

        // ── Quick Access Chips ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: QuickAccessRow(
            likesCount: feed.likesCount,
            totalTracks: state.totalTracks,
          ),
        ),
        const _SectionGap(),

        // ── Weekly Stats Banner (only when warm) ─────────────────────────
        if (!isColdStart && feed.weeklyPlayCount > 0)
          SliverToBoxAdapter(
            child: _WeeklyStatsBanner(playCount: feed.weeklyPlayCount),
          ),
        if (!isColdStart && feed.weeklyPlayCount > 0) const _SectionGap(),

        // ── Recently Played ──────────────────────────────────────────────
        if (feed.recentlyPlayed.length >= 2) ...[
          SliverToBoxAdapter(
            child: EntranceFader.staggered(
              index: 0,
              slideY: 0.05,
              child: SectionHeader(title: 'Recently Played'),
            ),
          ),
          SliverToBoxAdapter(
            child: RecentlyPlayedGrid(tracks: feed.recentlyPlayed),
          ),
          const _SectionGap(),
        ],

        // ── Top This Week ────────────────────────────────────────────────
        if (feed.topWeekly.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: EntranceFader.staggered(
              index: 0,
              slideY: 0.05,
              child: SectionHeader(title: 'Your Top This Week'),
            ),
          ),
          SliverToBoxAdapter(child: TopWeeklyRow(items: feed.topWeekly)),
          const _SectionGap(),
        ],

        // ── Hidden Gems ──────────────────────────────────────────────────
        if (feed.hiddenGems.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: EntranceFader.staggered(
              index: 0,
              slideY: 0.05,
              child: SectionHeader(title: 'Hidden Gems 💎'),
            ),
          ),
          SliverToBoxAdapter(child: HiddenGemsRow(tracks: feed.hiddenGems)),
          const _SectionGap(),
        ],

        // ── Your Artists ─────────────────────────────────────────────────
        if (feed.yourArtists.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: EntranceFader.staggered(
              index: 0,
              slideY: 0.05,
              child: SectionHeader(
                title: 'Your Artists',
                onViewAll: () {
                  context.read<LibraryBloc>().add(
                    const LibraryFilterChanged(LibraryFilter.artists),
                  );
                  context.go(AppRoute.library);
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: feed.yourArtists.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, i) => EntranceFader.staggered(
                  key: ValueKey('artist-${feed.yourArtists[i].id}'),
                  index: i,
                  slideY: 0.04,
                  child: ArtistCard(artist: feed.yourArtists[i], size: 100),
                ),
              ),
            ),
          ),
          const _SectionGap(),
        ],

        // ── New in Library (Albums) ──────────────────────────────────────
        if (feed.newAlbums.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: EntranceFader.staggered(
              index: 0,
              slideY: 0.05,
              child: SectionHeader(
                title: 'New in Library',
                onViewAll: () {
                  context.read<LibraryBloc>().add(
                    const LibraryFilterChanged(LibraryFilter.albums),
                  );
                  context.go(AppRoute.library);
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: feed.newAlbums.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, i) => EntranceFader.staggered(
                  key: ValueKey('album-${feed.newAlbums[i].id}'),
                  index: i,
                  slideY: 0.04,
                  child: AlbumCard(album: feed.newAlbums[i], size: 130),
                ),
              ),
            ),
          ),
          const _SectionGap(),
        ],

        // ── Your Playlists ───────────────────────────────────────────────
        if (feed.yourPlaylists.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: EntranceFader.staggered(
              index: 0,
              slideY: 0.05,
              child: SectionHeader(title: 'Your Playlists'),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: feed.yourPlaylists.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, i) => EntranceFader.staggered(
                  key: ValueKey('playlist-${feed.yourPlaylists[i].id}'),
                  index: i,
                  slideY: 0.04,
                  child: PlaylistCard(
                    playlist: feed.yourPlaylists[i],
                    size: 130,
                  ),
                ),
              ),
            ),
          ),
        ],

        // ── Bottom safe-area padding ─────────────────────────────────────
        SliverPadding(
          padding: EdgeInsets.only(
            bottom:
                AppSpacing.bottomBlockHeight +
                MediaQuery.of(context).padding.bottom +
                AppSpacing.md,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header — greeting + settings icon
// ─────────────────────────────────────────────────────────────────────────────

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
    return SafeArea(
      bottom: false,
      child:
          Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Welcome back to your music',
                            style: TextStyle(
                              color: context.colors.labelSecondary,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GlassIconButton(
                      icon: LucideIcons.settings,
                      onTap: () => context.pushNamed(AppRoute.settings),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: -0.1, end: 0, curve: Curves.easeOutCubic),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Weekly Stats Banner — compact glass card with play count
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklyStatsBanner extends StatelessWidget {
  final int playCount;

  const _WeeklyStatsBanner({required this.playCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: EntranceFader.staggered(
        index: 0,
        slideY: 0.04,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                context.colors.accent.withValues(alpha: .08),
                context.colors.accent.withValues(alpha: .03),
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: context.colors.accent.withValues(alpha: .15),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.barChart3,
                color: context.colors.accent,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: context.colors.labelSecondary,
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text: '$playCount ',
                        style: TextStyle(
                          color: context.colors.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const TextSpan(text: 'plays this week'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Gap — consistent vertical spacing between home sections
// ─────────────────────────────────────────────────────────────────────────────

class _SectionGap extends StatelessWidget {
  const _SectionGap();

  @override
  Widget build(BuildContext _) =>
      const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl));
}
