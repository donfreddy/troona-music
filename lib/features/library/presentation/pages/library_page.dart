import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/artist_card.dart';
import 'package:troona/features/library/presentation/widgets/library_segment_control.dart';
import 'package:troona/features/library/presentation/widgets/track_context_menu.dart';
import 'package:troona/features/library/presentation/widgets/track_list_tile.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/services/scanner/media_scanner_service.dart';
import 'package:troona/shared/widgets/custom_sliver_header.dart';
import 'package:troona/shared/widgets/empty_state.dart';
import 'package:troona/shared/widgets/error_view.dart';
import 'package:troona/shared/widgets/glass_card.dart';
import 'package:troona/features/library/presentation/widgets/track_shimmer.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  void initState() {
    super.initState();
    // Déclenche le scan au premier lancement uniquement si Initial
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
          // Header large title iOS
          BlocSelector<LibraryBloc, LibraryState, LibraryFilter>(
            selector: _selectedFilterFromState,
            builder: (context, filter) => CustomSliverHeader(
              title: 'Library',
              actions: [
                _SortButton(),
                SizedBox(width: AppSpacing.sm),
                GlassIconButton(
                  icon: LucideIcons.refreshCw,
                  onTap: () => context.read<LibraryBloc>().add(
                    const LibraryRefreshRequested(),
                  ),
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

          // Barre de progression scan (hauteur 0 si pas de scan)
          SliverToBoxAdapter(
            child: BlocBuilder<LibraryBloc, LibraryState>(
              buildWhen: (prev, curr) =>
                  (prev is LibraryScanning) != (curr is LibraryScanning) ||
                  (prev is LibraryScanning &&
                      curr is LibraryScanning &&
                      prev.progress != curr.progress),
              builder: (_, state) {
                if (state is! LibraryScanning) {
                  return const SizedBox.shrink();
                }
                return _ScanBanner(progress: state.progress);
              },
            ),
          ),

          // Corps principal switché sur le state
          BlocBuilder<LibraryBloc, LibraryState>(
            buildWhen: (prev, curr) => _bodyKey(prev) != _bodyKey(curr),
            builder: (context, state) => switch (state) {
              LibraryInitial() => const SliverFillRemaining(
                child: _FirstLaunchEmpty(),
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
                  message: state.message,
                  onRetry: () => context.read<LibraryBloc>().add(
                    const LibraryScanRequested(),
                  ),
                ),
              ),
            },
          ),

          // Padding bas
          SliverPadding(
            padding: EdgeInsets.only(
              bottom:
                  AppSpacing.bottomBlockHeight +
                  MediaQuery.of(context).padding.bottom +
                  AppSpacing.md,
            ),
          ),
        ],
      ),
    );
  }

  // Clé de comparaison pour limiter les rebuilds du body
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

// Corps des listes selon le filtre actif
class _LibraryBody extends StatelessWidget {
  final LibraryLoaded loaded;

  const _LibraryBody({required this.loaded});

  @override
  Widget build(BuildContext context) {
    return switch (loaded.filter) {
      LibraryFilter.all => _AllView(loaded: loaded),
      LibraryFilter.tracks => _TracksView(tracks: loaded.visibleTracks),
      LibraryFilter.albums => _AlbumsView(albums: loaded.visibleAlbums),
      LibraryFilter.artists => _ArtistsView(artists: loaded.visibleArtists),
    };
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

// ── Vue "Tout" ────────────────────────────────────────────

class _AllView extends StatelessWidget {
  final LibraryLoaded loaded;

  const _AllView({required this.loaded});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        // Section Albums (grille horizontale scrollable)
        if (loaded.visibleAlbums.isNotEmpty) ...[
          const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl)),
          _SectionHeader(
            title: 'Albums',
            onViewAll: () => context.read<LibraryBloc>().add(
              const LibraryFilterChanged(LibraryFilter.albums),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: loaded.visibleAlbums.take(10).length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, i) => _animatedLibraryItem(
                  AlbumCard(album: loaded.visibleAlbums[i]),
                  i,
                  slideY: .04,
                ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.sm)),
        ],

        // Section Titres
        if (loaded.visibleTracks.isNotEmpty) ...[
          const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl)),
          _SectionHeader(
            title: 'Titres',
            onViewAll: () => context.read<LibraryBloc>().add(
              const LibraryFilterChanged(LibraryFilter.tracks),
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

// ── Vue Titres ────────────────────────────────────────────

class _TracksView extends StatelessWidget {
  final List<Track> tracks;
  final bool compact;

  const _TracksView({required this.tracks, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return const SliverFillRemaining(
        child: EmptyState(
          message: 'Aucun titre trouvé',
          icon: Icons.music_note_rounded,
        ),
      );
    }
    return SliverList.separated(
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
    );
  }

  void _showContextMenu(BuildContext context, Track track) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => TrackContextMenu(track: track),
    );
  }
}

// ── Vue Albums ────────────────────────────────────────────

class _AlbumsView extends StatelessWidget {
  final List<Album> albums;

  const _AlbumsView({required this.albums});

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return SliverFillRemaining(
        child: EmptyState(
          message: 'Aucun album trouvé',
          icon: LucideIcons.disc,
        ),
      );
    }
    return SliverPadding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg) +
          const EdgeInsets.only(top: AppSpacing.lg),

      //todo: Also check when miniPlayer is not showing
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          // crossAxisSpacing: AppSpacing.md,
          // mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.86,
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

// ── Vue Artistes ──────────────────────────────────────────

class _ArtistsView extends StatelessWidget {
  final List<Artist> artists;

  const _ArtistsView({required this.artists});

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) {
      return const SliverFillRemaining(
        child: EmptyState(
          message: 'Aucune artiste trouvée',
          icon: Icons.person,
        ),
      );
    }
    return SliverPadding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg) +
          const EdgeInsets.only(top: AppSpacing.lg),
      //todo: Also check when miniPlayer is not showing
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          // crossAxisSpacing: AppSpacing.md,
          // mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.86,
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

// ── Section header ────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const _SectionHeader({required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: _animatedLibraryItem(
        Padding(
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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: context.colors.labelPrimary,
                ),
              ),
              if (onViewAll != null)
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
              // CupertinoButton(
              //   padding: EdgeInsets.zero,
              //   onPressed: onViewAll,
              //   child: Text(
              //     'View all',
              //     style: context.textTheme.labelLarge?.copyWith(
              //       color: context.colors.accent,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
        0,
        slideY: .05,
      ),
    );
  }
}

// ── Scan banner ───────────────────────────────────────────

class _ScanBanner extends StatelessWidget {
  final ScanProgress progress;

  const _ScanBanner({required this.progress});

  @override
  Widget build(BuildContext context) {
    final isIndeterminate = progress.phase == ScanPhase.scanning;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: GlassCard(
        config: GlassTheme.card(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Spinner si indéterminé
                if (isIndeterminate) ...[
                  SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.colors.accent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    _phaseLabel,
                    style: context.textTheme.labelLarge?.copyWith(
                      color: context.colors.labelSecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (!isIndeterminate) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress.progress,
                  minHeight: 3,
                  backgroundColor: context.colors.separator,
                  color: context.colors.accent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String get _phaseLabel => switch (progress.phase) {
    ScanPhase.scanning => 'Recherche des fichiers audio…',
    ScanPhase.indexing =>
      progress.total > 0
          ? 'Indexation  ${progress.count} / ${progress.total}'
          : 'Indexation…',
    ScanPhase.artworks =>
      progress.total > 0
          ? 'Pochettes  ${progress.count} / ${progress.total}'
          : 'Chargement des pochettes…',
    ScanPhase.done => 'Bibliothèque à jour',
  };
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
          icon: LucideIcons.arrowDownNarrowWide,
        );
      },
    );
  }

  void _showSortSheet(BuildContext context, LibrarySort current) {
    showCupertinoModalPopup<LibrarySort>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Trier par'),
        actions: LibrarySort.values.map((sort) {
          final label = switch (sort) {
            LibrarySort.title => 'Titre',
            LibrarySort.artist => 'Artiste',
            LibrarySort.album => 'Album',
            LibrarySort.dateAdded => 'Date d\'ajout',
          };
          return CupertinoActionSheetAction(
            isDefaultAction: sort == current,
            onPressed: () {
              context.read<LibraryBloc>().add(LibrarySortChanged(sort));
              context.pop();
            },
            child: Text(label),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => context.pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

// ── Empty states ──────────────────────────────────────────

class _FirstLaunchEmpty extends StatelessWidget {
  const _FirstLaunchEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.music_note_2,
            size: 64,
            color: context.colors.labelTertiary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Aucune musique trouvée',
            style: context.textTheme.headlineSmall?.copyWith(
              color: context.colors.labelPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Lance un scan pour indexer\nles fichiers audio de ton appareil.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.labelSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl2),
          CupertinoButton.filled(
            onPressed: () =>
                context.read<LibraryBloc>().add(const LibraryScanRequested()),
            child: const Text('Scanner la bibliothèque'),
          ),
        ],
      ),
    );
  }
}
