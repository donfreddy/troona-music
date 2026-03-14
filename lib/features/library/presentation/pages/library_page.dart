import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/bloc/library_bloc.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/artist_card.dart';
import 'package:troona/features/library/presentation/widgets/library_search_bar.dart';
import 'package:troona/features/library/presentation/widgets/library_segment_control.dart';
import 'package:troona/features/library/presentation/widgets/track_context_menu.dart';
import 'package:troona/features/library/presentation/widgets/track_list_tile.dart';
import 'package:troona/features/player/presentation/bloc/player_bloc.dart';
import 'package:troona/services/scanner/media_scanner_service.dart';
import 'package:troona/shared/widgets/custom_sliver_header.dart';
import 'package:troona/shared/widgets/empty_state.dart';
import 'package:troona/shared/widgets/error_view.dart';
import 'package:troona/shared/widgets/glass_card.dart';
import 'package:troona/features/library/presentation/widgets/track_shimmer.dart';

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
      // Fond : artwork flouté de la piste en cours (si player actif)
      // Sinon fond système. Géré par BlurredArtworkBackground.
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Fond dynamique artwork ──────────────────────
          //const BlurredArtworkBackground(),

          // ── Contenu principal ───────────────────────────
          CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Header large title iOS
              BlocSelector<LibraryBloc, LibraryState, LibraryFilter>(
                selector: (s) =>
                    s is LibraryLoaded ? s.filter : LibraryFilter.all,
                builder: (context, filter) => CustomSliverHeader(
                  title: 'Bibliothèque',
                  actions: [
                    _SortButton(),
                    IconButton(
                      icon: const Icon(CupertinoIcons.arrow_clockwise),
                      onPressed: () => context.read<LibraryBloc>().add(
                        const LibraryRefreshRequested(),
                      ),
                    ),
                  ],
                  bottom: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LibrarySearchBar(),
                      const SizedBox(height: AppSpacing.sm),
                      LibrarySegmentControl(
                        selected: filter,
                        onChanged: (f) => context.read<LibraryBloc>().add(
                          LibraryFilterChanged(f),
                        ),
                      ),
                    ],
                  ),
                  expandedHeight: 180,
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

                  LibraryScanning(:final cached) => _LibraryBody(
                    loaded: cached!,
                  ),

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

              // Padding bas pour le mini player
              const SliverPadding(
                padding: EdgeInsets.only(
                  bottom: AppSpacing.miniPlayerHeight + 16,
                ),
              ),
            ],
          ),

          // ── Mini player persistant ──────────────────────
          // const Positioned(
          //   bottom: 0, left: 0, right: 0,
          //   child: MiniPlayer(),
          // ),
        ],
      ),
    );
  }

  // Clé de comparaison pour limiter les rebuilds du body
  Object? _bodyKey(LibraryState s) => switch (s) {
    LibraryLoaded(
      :final visibleTracks,
      :final visibleAlbums,
      :final filter,
      :final sort,
      :final searchQuery,
    ) =>
      (visibleTracks.length, visibleAlbums.length, filter, sort, searchQuery),
    LibraryScanning(:final cached) => (
      'scanning',
      cached?.visibleTracks.length,
    ),
    LibraryError() => 'error',
    LibraryInitial() => 'initial',
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
          _SectionHeader(
            title: 'Albums',
            onSeeAll: () => context.read<LibraryBloc>().add(
              const LibraryFilterChanged(LibraryFilter.albums),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: loaded.visibleAlbums.take(10).length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, i) =>
                    AlbumCard(album: loaded.visibleAlbums[i]),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.lg)),
        ],

        // Section Titres
        if (loaded.visibleTracks.isNotEmpty) ...[
          _SectionHeader(
            title: 'Titres',
            onSeeAll: () => context.read<LibraryBloc>().add(
              const LibraryFilterChanged(LibraryFilter.tracks),
            ),
          ),
          _TracksView(
            tracks: loaded.visibleTracks.take(5).toList(),
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
      itemBuilder: (context, i) => TrackListTile(
        track: tracks[i],
        onTap: () => context.read<PlayerBloc>().add(
          PlayTrackRequested(tracks[i], contextQueue: tracks, contextIndex: i),
        ),
        onLongPress: () => _showContextMenu(context, tracks[i]),
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
      return const SliverFillRemaining(
        child: EmptyState(
          message: 'Aucun album trouvé',
          icon: Icons.album_rounded,
        ),
      );
    }
    // Grille 2 colonnes, style Apple Music
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.82, // artwork carré + titre en dessous
        ),
        itemCount: albums.length,
        itemBuilder: (context, i) => AlbumCard(album: albums[i]),
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
    return SliverList.separated(
      itemCount: artists.length,
      separatorBuilder: (_, _) =>
          Divider(height: 0.5, indent: 60, color: context.colors.separator),
      itemBuilder: (context, i) => ArtistCard(artist: artists[i]),
    );
  }
}

// ── Section header ────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: context.textTheme.headlineSmall?.copyWith(
                color: context.colors.labelPrimary,
              ),
            ),
            if (onSeeAll != null)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onSeeAll,
                child: Text(
                  'Voir tout',
                  style: context.textTheme.labelLarge?.copyWith(
                    color: context.colors.accent,
                  ),
                ),
              ),
          ],
        ),
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
        return CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showSortSheet(context, sort),
          child: Icon(CupertinoIcons.sort_down, color: context.colors.accent),
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
              Navigator.of(context).pop();
            },
            child: Text(label),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
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
