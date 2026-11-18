import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
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
import 'package:troona/features/library/presentation/widgets/library_index.dart';
import 'package:troona/features/library/presentation/widgets/library_segment_control.dart';
import 'package:troona/features/library/presentation/widgets/track_actions/show_track_actions.dart';
import 'package:troona/features/library/presentation/widgets/track_list_tile.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/action_sheet.dart';
import 'package:troona/shared/widgets/glass_sliver_header.dart';
import 'package:troona/shared/widgets/app_toast.dart';
import 'package:troona/shared/widgets/empty_state.dart';
import 'package:troona/shared/widgets/entrance_fader.dart';
import 'package:troona/shared/widgets/error_view.dart';
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
  /// Height of the filter pinned under the navigation row.
  static const double _pinnedBottomHeight =
      AppSpacing.tabBarHeight + AppSpacing.xl;

  /// The list or grid of the filter shown, which the index scrolls.
  final _listKey = GlobalKey();

  /// Scrolls so the item at [index] of the list shown sits just under the
  /// collapsed header. Its place is known without building it: the songs
  /// have one height, the grids one row height.
  void _jumpTo(int index) {
    final context = _listKey.currentContext;
    final sliver = context?.findRenderObject();
    if (context == null || sliver is! RenderSliver) return;
    final double offset;
    switch (sliver) {
      case RenderSliverFixedExtentBoxAdaptor(:final itemExtent?):
        offset = index * itemExtent;
      case RenderSliverGrid(:final gridDelegate, :final constraints):
        offset = gridDelegate
            .getLayout(constraints)
            .getGeometryForChildIndex(index)
            .scrollOffset;
      default:
        return;
    }
    final position = Scrollable.of(context).position;
    final pinned =
        GlassSliverHeader.navBarBottom(this.context) + _pinnedBottomHeight;
    final target = sliver.constraints.precedingScrollExtent + offset - pinned;
    position.jumpTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
    );
  }

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
      body: Stack(
        children: [
          _scrollView(context),
          BlocBuilder<LibraryBloc, LibraryState>(
            buildWhen: (prev, curr) => _bodyKey(prev) != _bodyKey(curr),
            builder: (context, state) {
              final loaded = _loadedOf(state);
              final texts = loaded == null ? null : libraryIndexTexts(loaded);
              if (texts == null) return const SizedBox.shrink();
              return Positioned.fill(
                child: LibraryIndex(
                  sections: LibraryIndexSections.of(texts),
                  onSection: (section) => _jumpTo(section.index),
                  // Below the expanded header: its filter takes touches.
                  top:
                      GlassSliverHeader.navBarBottom(context) +
                      GlassSliverHeader.largeTitleExtentOf(context) +
                      _pinnedBottomHeight,
                  bottom: context.bottomBarInset(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  LibraryLoaded? _loadedOf(LibraryState state) => switch (state) {
    LibraryLoaded() => state,
    LibraryScanning(:final cached?) => cached,
    LibraryError(:final lastLoaded?) => lastLoaded,
    _ => null,
  };

  Widget _scrollView(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        BlocSelector<LibraryBloc, LibraryState, LibraryFilter>(
          selector: _selectedFilterFromState,
          builder: (context, filter) => GlassSliverHeader.largeTitle(
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
            pinnedBottom: LibrarySegmentControl(
              selected: filter,
              onChanged: (f) =>
                  context.read<LibraryBloc>().add(LibraryFilterChanged(f)),
            ),
            pinnedBottomHeight: _pinnedBottomHeight,
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

            LibraryScanning(:final cached) => _LibraryBody(
              loaded: cached!,
              listKey: _listKey,
            ),

            LibraryLoaded() => _LibraryBody(loaded: state, listKey: _listKey),

            LibraryError(:final lastLoaded) when lastLoaded != null =>
              _LibraryBody(loaded: lastLoaded, listKey: _listKey),

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

/// What the index files the list shown under, in its order: the key it is
/// sorted by. Null when there is no index: the All view, songs by date
/// added, or a list short enough to scroll through.
@visibleForTesting
List<String>? libraryIndexTexts(LibraryLoaded loaded) {
  final texts = switch (loaded.filter) {
    LibraryFilter.all => null,
    LibraryFilter.tracks => switch (loaded.sort) {
      LibrarySort.title => [for (final t in loaded.visibleTracks) t.title],
      LibrarySort.artist => [for (final t in loaded.visibleTracks) t.artist],
      LibrarySort.album => [for (final t in loaded.visibleTracks) t.album],
      LibrarySort.dateAdded => null,
    },
    LibraryFilter.albums => [
      for (final a in loaded.visibleAlbums)
        loaded.sort == LibrarySort.artist ? a.artist : a.name,
    ],
    LibraryFilter.artists => [for (final a in loaded.visibleArtists) a.name],
  };
  if (texts == null || texts.length < libraryIndexMinItems) return null;
  return texts;
}

/// The fewest items a list has to be worth an index.
const libraryIndexMinItems = 20;

// Lists for the active filter
class _LibraryBody extends StatefulWidget {
  final LibraryLoaded loaded;

  /// Given to the list or grid shown, which the index scrolls.
  final GlobalKey listKey;

  const _LibraryBody({required this.loaded, required this.listKey});

  @override
  State<_LibraryBody> createState() => _LibraryBodyState();
}

class _LibraryBodyState extends State<_LibraryBody> {
  late Duration _shownAt = _now;

  static Duration get _now => SchedulerBinding.instance.currentFrameTimeStamp;

  @override
  void didUpdateWidget(_LibraryBody old) {
    super.didUpdateWidget(old);
    // A new list, not a new read of the same one: a rescan gives every
    // item anew, and would replay the entrance of the rows in view.
    final (a, b) = (widget.loaded, old.loaded);
    if (a.filter != b.filter ||
        a.sort != b.sort ||
        a.searchQuery != b.searchQuery) {
      _shownAt = _now;
    }
  }

  @override
  Widget build(BuildContext context) =>
      _Entrance(shownAt: _shownAt, child: _list(context));

  Widget _list(BuildContext context) {
    final loaded = widget.loaded;
    final listKey = widget.listKey;
    if (loaded.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: _NoMusicEmpty(),
      );
    }
    // No counts banner: the filter and the sections' See all already lead
    // to each list.
    final indexed = libraryIndexTexts(loaded) != null;
    return switch (loaded.filter) {
      LibraryFilter.all => _AllView(loaded: loaded),
      LibraryFilter.tracks => _TracksView(
        tracks: loaded.visibleTracks,
        listKey: listKey,
        indexed: indexed,
      ),
      LibraryFilter.albums => _AlbumsView(
        albums: loaded.visibleAlbums,
        listKey: listKey,
        indexed: indexed,
      ),
      LibraryFilter.artists => _ArtistsView(
        artists: loaded.visibleArtists,
        listKey: listKey,
        indexed: indexed,
      ),
    };
  }
}

/// The frame the list shown came in: the items built in it play their
/// entrance, the ones scrolling or the index bring in later show at once
/// (a jump to a letter would otherwise leave the screen empty while they
/// wait their turn).
class _Entrance extends InheritedWidget {
  final Duration shownAt;

  const _Entrance({required this.shownAt, required super.child});

  static bool playing(BuildContext context) {
    final entrance = context.getInheritedWidgetOfExactType<_Entrance>();
    if (entrance == null) return true;
    return SchedulerBinding.instance.currentFrameTimeStamp == entrance.shownAt;
  }

  @override
  bool updateShouldNotify(_Entrance old) => false;
}

Widget _animatedLibraryItem(
  BuildContext context,
  Widget child,
  int index, {
  double slideY = .08,
}) => EntranceFader.staggered(
  // Keyed by its place, not by the item it holds (the fader would take
  // the card's key): a new sort reuses the slots on screen instead of
  // building them anew in the frame the entrance plays.
  key: ValueKey('entry-$index'),
  index: index,
  stepMs: 40,
  maxDelayMs: 240,
  duration: const Duration(milliseconds: 360),
  slideY: slideY,
  play: _Entrance.playing(context),
  child: child,
);

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
                  context,
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
          // Ten at most: a row as tall as its names, which wrap under a
          // large font instead of overflowing a fixed height.
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, artist)
                      in loaded.visibleArtists.take(10).indexed) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.md),
                    _animatedLibraryItem(
                      context,
                      ArtistCard(artist: artist, size: 95),
                      i,
                      slideY: .04,
                    ),
                  ],
                ],
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

  /// The full list's key, for the index; null in the All view.
  final GlobalKey? listKey;

  /// Leaves the index its strip at the right edge.
  final bool indexed;

  const _TracksView({
    required this.tracks,
    this.compact = false,
    this.listKey,
    this.indexed = false,
  });

  /// A row of sample text: every row is as tall, whatever its names.
  Widget _prototype(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      TrackListTile(track: _sample, onTap: () {}),
      const Divider(height: 0.5),
    ],
  );

  static final _sample = Track(
    id: '',
    title: 'Ag',
    artist: 'Ag',
    artistId: 0,
    album: '',
    albumId: 0,
    path: '',
    uri: '',
    size: 0,
    durationMs: 0,
    fileName: '',
  );

  Widget _row(BuildContext context, int i) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      TrackListTile(
        key: ValueKey(
          'track-${tracks[i].id}-${compact ? 'compact' : 'full'}-$i',
        ),
        track: tracks[i],
        onTap: () => context.read<PlayerBloc>().add(
          PlayTrackRequested(tracks[i], contextQueue: tracks, contextIndex: i),
        ),
        onLongPress: () => _showContextMenu(context, tracks[i]),
      ),
      Divider(
        height: 0.5,
        indent: 72,
        // Kept under the last one, unseen, so every row is one height.
        color: i == tracks.length - 1
            ? Colors.transparent
            : context.colors.separator,
      ),
    ],
  );

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
        if (!compact)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(right: indexed ? LibraryIndex.width : 0),
              child: ShuffleBanner(tracks: tracks),
            ),
          ),
        // One height for every song, its line under it included: the index
        // knows where the nth one is without building the ones above.
        SliverPrototypeExtentList.builder(
          key: listKey,
          prototypeItem: _prototype(context),
          itemCount: tracks.length,
          itemBuilder: (context, i) => _animatedLibraryItem(
            context,
            Padding(
              padding: EdgeInsets.only(right: indexed ? LibraryIndex.width : 0),
              child: _row(context, i),
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
  final GlobalKey listKey;
  final bool indexed;

  const _AlbumsView({
    required this.albums,
    required this.listKey,
    required this.indexed,
  });

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
      padding: _gridPadding(indexed),
      sliver: SliverGrid.builder(
        key: listKey,
        gridDelegate: _CardGrid(
          columns: 2,
          textHeight: AlbumCard.textHeight(context),
        ),
        itemCount: albums.length,
        itemBuilder: (context, i) => _animatedLibraryItem(
          context,
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
  final GlobalKey listKey;
  final bool indexed;

  const _ArtistsView({
    required this.artists,
    required this.listKey,
    required this.indexed,
  });

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
      padding: _gridPadding(indexed),
      sliver: SliverGrid.builder(
        key: listKey,
        // Three across: a circle reads at a third of the width, and twice
        // as many artists fit on a screen.
        gridDelegate: _CardGrid(
          columns: 3,
          textHeight: ArtistCard.textHeight(context),
        ),
        itemCount: artists.length,
        itemBuilder: (context, i) => _animatedLibraryItem(
          context,
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

// ── Grids ─────────────────────────────────────────────────

/// The page margins around a grid, its right one wide enough for the
/// index's strip when there is one.
EdgeInsets _gridPadding(bool indexed) => EdgeInsets.fromLTRB(
  AppSpacing.lg,
  AppSpacing.lg,
  indexed ? LibraryIndex.width + AppSpacing.xs : AppSpacing.lg,
  0,
);

/// [columns] square covers across, each cell as tall as its cover and the
/// [textHeight] under it: no room left empty between the rows.
class _CardGrid extends SliverGridDelegate {
  final int columns;
  final double textHeight;

  const _CardGrid({required this.columns, required this.textHeight});

  static const double _across = AppSpacing.md;
  static const double _down = AppSpacing.lg;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final cell =
        (constraints.crossAxisExtent - _across * (columns - 1)) / columns;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      crossAxisSpacing: _across,
      mainAxisSpacing: _down,
      mainAxisExtent: cell + textHeight,
    ).getLayout(constraints);
  }

  @override
  bool shouldRelayout(_CardGrid old) =>
      old.columns != columns || old.textHeight != textHeight;
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
