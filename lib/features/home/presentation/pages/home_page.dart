import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/home/presentation/bloc/home_bloc.dart';
import 'package:troona/features/home/presentation/widgets/hidden_gems_row.dart';
import 'package:troona/features/home/presentation/widgets/home_hero_banner.dart';
import 'package:troona/features/home/presentation/widgets/online_extras_offer.dart';
import 'package:troona/features/home/presentation/widgets/quick_access_row.dart';
import 'package:troona/features/home/presentation/widgets/recently_played_grid.dart';
import 'package:troona/features/home/presentation/widgets/top_weekly_row.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/artist_card.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/playlist/presentation/widgets/playlist_card.dart';
import 'package:troona/shared/widgets/entrance_fader.dart';
import 'package:troona/shared/widgets/error_view.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';
import 'package:troona/shared/widgets/section_heater.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomePage: Troona's adaptive home feed
// ─────────────────────────────────────────────────────────────────────────────
//
// Three states, driven by the library size and the listening history:
// empty (no music), fresh (music, no plays yet) and warm (stats-driven feed).
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
            SliverToBoxAdapter(
              child: BlocBuilder<HomeBloc, HomeState>(
                buildWhen: (a, b) => _subtitleKey(a) != _subtitleKey(b),
                builder: (context, state) =>
                    _HomeHeader(subtitle: _subtitleOf(context, state)),
              ),
            ),
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
                    hasScrollBody: false,
                    child: ErrorView(
                      body: context.l10n.homeLoadError,
                      onRetry: () =>
                          context.read<HomeBloc>().add(HomeRefreshRequested()),
                    ),
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

  static Object? _subtitleKey(HomeState state) => switch (state) {
    HomeLoaded(:final feed, :final totalTracks) => (
      feed.isColdStart,
      totalTracks,
    ),
    _ => null,
  };

  static String? _subtitleOf(BuildContext context, HomeState state) {
    if (state is! HomeLoaded || state.totalTracks == 0) return null;
    return state.feed.isColdStart
        ? context.l10n.homeSongsReady(state.totalTracks)
        : context.l10n.homeSubtitleWarm;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home body: assembles all sections based on feed state
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
            totalTracks: state.totalTracks,
            onShuffleAll: () => shuffleWholeLibrary(context),
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
            onScanAgain: () {
              context.read<LibraryBloc>().add(LibraryScanRequested());
              context.go(AppRoute.library);
            },
          ),
        ),
        const _SectionGap(),

        if (state.totalTracks > 0)
          const SliverToBoxAdapter(child: OnlineExtrasOffer()),

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
              child: SectionHeader(title: context.l10n.homeRecentlyPlayed),
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
              child: SectionHeader(title: context.l10n.homeOnRepeat),
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
              child: SectionHeader(title: context.l10n.homeRediscover),
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
                title: context.l10n.homeYourArtists,
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

        // ── Recently added albums ────────────────────────────────────────
        if (feed.newAlbums.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: EntranceFader.staggered(
              index: 0,
              slideY: 0.05,
              child: SectionHeader(
                title: context.l10n.homeRecentlyAdded,
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
              height: 200,
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
              child: SectionHeader(title: context.l10n.homeYourPlaylists),
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
// Header: greeting and settings button
// ─────────────────────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final String? subtitle;

  const _HomeHeader({required this.subtitle});

  static String _greeting(BuildContext context) {
    final l10n = context.l10n;
    return switch (DateTime.now().hour) {
      >= 5 && < 12 => l10n.homeGreetingMorning,
      >= 12 && < 18 => l10n.homeGreetingAfternoon,
      >= 18 && < 23 => l10n.homeGreetingEvening,
      _ => l10n.homeGreetingNight,
    };
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
                            _greeting(context),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: TextStyle(
                                color: context.colors.labelSecondary,
                                fontSize: 17,
                              ),
                            ),
                        ],
                      ),
                    ),
                    GlassIconButton(
                      icon: LucideIcons.settings,
                      tooltip: context.l10n.settingsTitle,
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
// Weekly stats banner: compact card with the play count
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
                      TextSpan(text: context.l10n.homeWeeklyPlays(playCount)),
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
// Section gap: consistent vertical spacing between home sections
// ─────────────────────────────────────────────────────────────────────────────

class _SectionGap extends StatelessWidget {
  const _SectionGap();

  @override
  Widget build(BuildContext _) =>
      const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl));
}
