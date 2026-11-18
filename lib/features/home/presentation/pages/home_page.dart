import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/history/presentation/cubit/listening_recap_cubit.dart';
import 'package:troona/features/history/presentation/widgets/recap_clock.dart';
import 'package:troona/features/history/presentation/widgets/weekly_recap_card.dart';
import 'package:troona/features/home/presentation/bloc/home_bloc.dart';
import 'package:troona/features/home/presentation/widgets/hidden_gems_row.dart';
import 'package:troona/features/home/presentation/widgets/home_hero_banner.dart';
import 'package:troona/features/home/presentation/widgets/home_system_card.dart';
import 'package:troona/features/home/presentation/widgets/quick_access_row.dart';
import 'package:troona/features/home/presentation/widgets/recently_played_grid.dart';
import 'package:troona/features/home/presentation/widgets/top_weekly_row.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/entrance_fader.dart';
import 'package:troona/shared/widgets/error_view.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';
import 'package:troona/shared/widgets/glass_sliver_header.dart';
import 'package:troona/shared/widgets/section_header.dart';
import 'package:troona/core/utils/haptics_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomePage: Troona's adaptive home feed
// ─────────────────────────────────────────────────────────────────────────────
//
// Three states, driven by the library size and the listening history:
// empty (no music), fresh (music, no plays yet) and warm (stats-driven feed).
// ─────────────────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  /// What the line under the greeting says. Empty or cold start: nothing,
  /// the hero card already says what to do next. Else this week's plays,
  /// the one figure Home keeps out of a card of its own.
  @visibleForTesting
  static String? subtitleOf(AppLocalizations l10n, HomeState state) {
    if (state is! HomeLoaded) return null;
    if (state.totalTracks == 0 || state.feed.isColdStart) return null;
    final plays = state.feed.weeklyPlayCount;
    // Unknown: no line rather than a wrong "nothing this week".
    if (plays == null) return null;
    if (plays == 0) return l10n.homeSubtitleWarm;
    return l10n.homeWeeklyPlays(plays);
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // A feed kept from yesterday catches up with today when the app comes
  // back (the week's plays start again on Mondays).
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<HomeBloc>().add(const HomeResumed()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        // Below the glass bar, which stays on top of the scroll view.
        edgeOffset: GlassSliverHeader.navBarBottom(context),
        onRefresh: () async {
          AppHaptics.lightImpact();
          context.read<HomeBloc>().add(HomeRefreshRequested());
          await context.read<ListeningRecapCubit>().load();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            GlassSliverHeader.largeTitle(
              title: _greeting(context),
              actions: [
                GlassIconButton(
                  icon: AppIcons.settings,
                  tooltip: context.l10n.settingsTitle,
                  onTap: () => context.pushNamed(AppRoute.settings),
                ),
              ],
            ),
            const SliverToBoxAdapter(child: HomeSubtitle()),
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

  static String _greeting(BuildContext context) {
    final l10n = context.l10n;
    return switch (DateTime.now().hour) {
      >= 5 && < 12 => l10n.homeGreetingMorning,
      >= 12 && < 18 => l10n.homeGreetingAfternoon,
      >= 18 && < 23 => l10n.homeGreetingEvening,
      _ => l10n.homeGreetingNight,
    };
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

        // One system card at a time: a new release, else the offer.
        SliverToBoxAdapter(
          child: HomeSystemCard(offerExtras: state.totalTracks > 0),
        ),

        // ── Quick Access Chips ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: QuickAccessRow(
            likesCount: feed.likesCount,
            totalTracks: state.totalTracks,
          ),
        ),
        const _SectionGap(),

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

        // ── Last week's recap: music comes first ────────────────────────
        const _WeeklySection(),

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

        // ── Bottom safe-area padding ─────────────────────────────────────
        SliverPadding(
          padding: EdgeInsets.only(bottom: context.bottomBarInset()),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subtitle under the greeting, which is the page's large title
// ─────────────────────────────────────────────────────────────────────────────

/// The line under the greeting ([HomePage.subtitleOf]), rebuilt only when
/// what it says changes.
class HomeSubtitle extends StatelessWidget {
  const HomeSubtitle({super.key});

  static Object? _keyOf(HomeState state) => switch (state) {
    HomeLoaded(:final feed, :final totalTracks) => (
      feed.isColdStart,
      totalTracks == 0,
      feed.weeklyPlayCount,
    ),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      buildWhen: (a, b) => _keyOf(a) != _keyOf(b),
      builder: (context, state) =>
          _subtitleLine(context, HomePage.subtitleOf(context.l10n, state)),
    );
  }

  static Widget _subtitleLine(BuildContext context, String? subtitle) {
    if (subtitle == null) return const SizedBox(height: AppSpacing.md);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Text(
        subtitle,
        style: TextStyle(color: context.colors.labelSecondary, fontSize: 17),
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Last week's recap card, once it has plays
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklySection extends StatelessWidget {
  const _WeeklySection();

  @override
  Widget build(BuildContext context) {
    return RecapClock(
      child: BlocBuilder<ListeningRecapCubit, ListeningRecapState>(
        builder: (context, state) {
          final recap = state.recap;
          final Widget? content = recap != null && recap.plays > 0
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: EntranceFader.staggered(
                    index: 0,
                    slideY: 0.04,
                    child: WeeklyRecapCard(
                      recap: recap,
                      onTap: () => context.push(
                        '${AppRoute.home}/${AppRoute.weeklyRecap}',
                      ),
                    ),
                  ),
                )
              : null;
          if (content == null) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }
          return SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(child: content),
              const _SectionGap(),
            ],
          );
        },
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
