import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/artist_card.dart';
import 'package:troona/features/library/presentation/widgets/library_segment_control.dart';
import 'package:troona/features/library/presentation/widgets/track_actions/show_track_actions.dart';
import 'package:troona/features/library/presentation/widgets/track_list_tile.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/action_sheet.dart';
import 'package:troona/shared/widgets/custom_sliver_header.dart';
import 'package:troona/shared/widgets/app_toast.dart';
import 'package:troona/shared/widgets/empty_state.dart';
import 'package:troona/shared/widgets/error_view.dart';
import 'package:troona/features/library/presentation/widgets/library_stats_banner.dart';
import 'package:troona/features/library/presentation/widgets/shuffle_banner.dart';
import 'package:troona/features/library/presentation/widgets/track_shimmer.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';
import 'package:troona/shared/widgets/section_header.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  void initState() {
    super.initState();
    // First launch only: the shell bootstraps every later start.
    final bloc = context.read<LibraryBloc>();
    if (bloc.state is LibraryInitial) {
      bloc.add(const LibraryScanRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          BlocSelector<LibraryBloc, LibraryState, LibraryFilter>(
            selector: _selectedFilterFromState,
            builder: (context, filter) => CustomSliverHeader(
              title: context.l10n.navLibrary,
              actions: [
                _SortButton(),
                SizedBox(width: AppSpacing.sm),
                GlassIconButton(
                  icon: AppIcons.refresh,
                  tooltip: context.l10n.settingsRescan,
                  onTap: () {
                    // Rescans are silent; the shell toasts what changed.
                    AppToast.show(context, context.l10n.libraryUpdating);
                    context.read<LibraryBloc>().add(
                      const LibraryRefreshRequested(),
                    );
                  },
                ),
              ],
              bottom: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LibrarySegmentControl(
                    selected: filter,
                    onChanged: (f) => context.read<LibraryBloc>().add(
                      LibraryFilterChanged(f),
                    ),
                  ),
                ],
              ),
              bottomHeight: AppSpacing.tabBarHeight + AppSpacing.xl,
              expandedHeight: 130,
            ),
          ),

          BlocBuilder<LibraryBloc, LibraryState>(
            buildWhen: (prev, curr) => _bodyKey(prev) != _bodyKey(curr),
            builder: (context, state) => switch (state) {
              LibraryInitial() => const SliverFillRemaining(
                hasScrollBody: false,
                child: _NoMusicEmpty(),
              ),

              LibraryScanning(:final cached) when cached == null =>
                SliverList.builder(
                  itemCount: 20,
                  itemBuilder: (_, _) => const TrackShimmer(),
                ),

              LibraryScanning(:final cached) => _LibraryBody(loaded: cached!),

              LibraryLoaded() => _LibraryBody(loaded: state),

              LibraryError(:final lastLoaded) when lastLoaded != null =>
                _LibraryBody(loaded: lastLoaded),

              LibraryError() => SliverFillRemaining(
                child: ErrorView(
                  title: context.l10n.libraryLoadErrorTitle,
                  body: context.l10n.libraryLoadErrorBody,
                  onRetry: () => context.read<LibraryBloc>().add(
                    const LibraryScanRequested(),
                  ),
                ),
              ),
            },
          ),

          SliverPadding(
            padding: EdgeInsets.only(bottom: context.bottomBarInset()),
          ),
        ],
      ),
    );
  }

  // Comparison key that limits body rebuilds
  Object? _bodyKey(LibraryState s) => switch (s) {
    LibraryLoaded(
      :final visibleTracks,
      :final visibleAlbums,
      :final visibleArtists,
      :final filter,
      :final sort,
      :final searchQuery,
    ) =>
      (
        visibleTracks.length,
        visibleAlbums.length,
        visibleArtists.length,
        filter,
        sort,
        searchQuery,
      ),
    LibraryScanning(:final cached) => (
      'scanning',
      cached?.visibleTracks.length,
      cached?.visibleAlbums.length,
      cached?.visibleArtists.length,
      cached?.filter,
    ),
    LibraryError() => 'error',
    LibraryInitial() => 'initial',
  };

  LibraryFilter _selectedFilterFromState(LibraryState state) => switch (state) {
    LibraryLoaded(:final filter) => filter,
    LibraryScanning(:final cached?) => cached.filter,
    LibraryError(:final lastLoaded?) => lastLoaded.filter,
    _ => LibraryFilter.all,
  };
}

// Lists for the active filter
class _LibraryBody extends StatelessWidget {
  final LibraryLoaded loaded;

  const _LibraryBody({required this.loaded});

  @override
  Widget build(BuildContext context) {
    if (loaded.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: _NoMusicEmpty(),
      );
    }
    final statsBanner = SliverToBoxAdapter(
      child: LibraryStatsBanner(
        trackCount: loaded.allTracks.length,
        albumCount: loaded.allAlbums.length,
        artistCount: loaded.allArtists.length,
      ),
    );

    return SliverMainAxisGroup(
      slivers: [
        if (loaded.filter == LibraryFilter.all) statsBanner,
        switch (loaded.filter) {
          LibraryFilter.all => _AllView(loaded: loaded),
          LibraryFilter.tracks => _TracksView(tracks: loaded.visibleTracks),
          LibraryFilter.albums => _AlbumsView(albums: loaded.visibleAlbums),
          LibraryFilter.artists => _ArtistsView(artists: loaded.visibleArtists),
        },
      ],
    );
  }
}

Widget _animatedLibraryItem(
  Widget child,
  int index, {
  double slideY = .08,
  int stepMs = 40,
}) {
  final delay = Duration(milliseconds: (index * stepMs).clamp(0, 240));

  return child
      .animate(delay: delay)
      .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
      .slideY(
        begin: slideY,
        end: 0,
        duration: 360.ms,
        curve: Curves.easeOutCubic,
      );
}

// ── All ───────────────────────────────────────────────────

class _AllView extends StatelessWidget {
  final LibraryLoaded loaded;

  const _AllView({required this.loaded});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        if (loaded.visibleAlbums.isNotEmpty) ...[
          const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.sm)),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: context.l10n.libraryFilterAlbums,
              onViewAll: () => context.read<LibraryBloc>().add(
                const LibraryFilterChanged(LibraryFilter.albums),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 225,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: loaded.visibleAlbums.take(10).length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, i) => _animatedLibraryItem(
                  AlbumCard(album: loaded.visibleAlbums[i], size: 145),
                  i,
                  slideY: .04,
                ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.md)),
        ],

        if (loaded.visibleArtists.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHeader(
              title: context.l10n.libraryFilterArtists,
              onViewAll: () => context.read<LibraryBloc>().add(
                const LibraryFilterChanged(LibraryFilter.artists),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 145,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: loaded.visibleArtists.take(10).length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, i) => _animatedLibraryItem(
                  ArtistCard(artist: loaded.visibleArtists[i], size: 95),
                  i,
                  slideY: .04,
                ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.md)),
        ],

        if (loaded.visibleTracks.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHeader(
              title: context.l10n.libraryFilterSongs,
              onViewAll: () => context.read<LibraryBloc>().add(
                const LibraryFilterChanged(LibraryFilter.tracks),
              ),
            ),
          ),
          _TracksView(
            tracks: loaded.visibleTracks.take(10).toList(),
            compact: true,
          ),
        ],
      ],
    );
  }
}

// ── Songs ─────────────────────────────────────────────────

class _TracksView extends StatelessWidget {
  final List<Track> tracks;
  final bool compact;

  const _TracksView({required this.tracks, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          title: context.l10n.libraryNoSongs,
          icon: AppIcons.track,
        ),
      );
    }
    return SliverMainAxisGroup(
      slivers: [
        if (!compact) SliverToBoxAdapter(child: ShuffleBanner(tracks: tracks)),
        SliverList.separated(
          itemCount: tracks.length,
          separatorBuilder: (_, _) =>
              Divider(height: 0.5, indent: 72, color: context.colors.separator),
          itemBuilder: (context, i) => _animatedLibraryItem(
            TrackListTile(
              key: ValueKey(
                'track-${tracks[i].id}-${compact ? 'compact' : 'full'}-$i',
              ),
              track: tracks[i],
              onTap: () => context.read<PlayerBloc>().add(
                PlayTrackRequested(
                  tracks[i],
                  contextQueue: tracks,
                  contextIndex: i,
                ),
              ),
              onLongPress: () => _showContextMenu(context, tracks[i]),
            ),
            i,
          ),
        ),
      ],
    );
  }

  void _showContextMenu(BuildContext context, Track track) {
    showTrackActions(context, track, origin: TrackActionOrigin.library);
  }
}

// ── Albums ────────────────────────────────────────────────

class _AlbumsView extends StatelessWidget {
  final List<Album> albums;

  const _AlbumsView({required this.albums});

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          title: context.l10n.libraryNoAlbums,
          icon: AppIcons.album,
        ),
      );
    }
    return SliverPadding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg) +
          const EdgeInsets.only(top: AppSpacing.lg),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.lg,
          childAspectRatio: 0.70,
        ),
        itemCount: albums.length,
        itemBuilder: (context, i) => _animatedLibraryItem(
          AlbumCard(
            key: ValueKey('album-${albums[i].id}-$i'),
            album: albums[i],
          ),
          i,
          slideY: .06,
        ),
      ),
    );
  }
}

// ── Artists ───────────────────────────────────────────────

class _ArtistsView extends StatelessWidget {
  final List<Artist> artists;

  const _ArtistsView({required this.artists});

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          title: context.l10n.libraryNoArtists,
          icon: AppIcons.artist,
        ),
      );
    }
    return SliverPadding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg) +
          const EdgeInsets.only(top: AppSpacing.lg),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.lg,
          childAspectRatio: 0.75,
        ),
        itemCount: artists.length,
        itemBuilder: (context, i) => _animatedLibraryItem(
          ArtistCard(
            key: ValueKey('artist-${artists[i].id}-$i'),
            artist: artists[i],
          ),
          i,
          slideY: .06,
        ),
      ),
    );
  }
}

// ── Sort button ───────────────────────────────────────────

class _SortButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<LibraryBloc, LibraryState, LibrarySort>(
      selector: (s) => s is LibraryLoaded ? s.sort : LibrarySort.title,
      builder: (context, sort) {
        return GlassIconButton(
          onTap: () => _showSortSheet(context, sort),
          icon: AppIcons.sort,
          tooltip: context.l10n.librarySort,
        );
      },
    );
  }

  void _showSortSheet(BuildContext context, LibrarySort current) {
    final l10n = context.l10n;
    showActionSheet(
      context,
      title: l10n.librarySortBy,
      actions: [
        for (final sort in LibrarySort.values)
          SheetAction(
            label: switch (sort) {
              LibrarySort.title => l10n.librarySortTitle,
              LibrarySort.artist => l10n.librarySortArtist,
              LibrarySort.album => l10n.librarySortAlbum,
              LibrarySort.dateAdded => l10n.librarySortRecent,
            },
            selected: sort == current,
            onPressed: () =>
                context.read<LibraryBloc>().add(LibrarySortChanged(sort)),
          ),
      ],
    );
  }
}

// ── Empty states ──────────────────────────────────────────

class _NoMusicEmpty extends StatelessWidget {
  const _NoMusicEmpty();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyState(
      icon: AppIcons.track,
      title: l10n.libraryEmptyTitle,
      body: l10n.libraryEmptyBody,
      actionLabel: l10n.libraryScanAgain,
      onAction: () =>
          context.read<LibraryBloc>().add(const LibraryScanRequested()),
    );
  }
}
