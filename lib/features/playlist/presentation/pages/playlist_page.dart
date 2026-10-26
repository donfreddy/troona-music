import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/playlist/presentation/bloc/playlist/playlist_bloc.dart';
import 'package:troona/features/playlist/presentation/pages/playlist_editor_page.dart';
import 'package:troona/features/playlist/presentation/widgets/likes_hero_card.dart';
import 'package:troona/features/playlist/presentation/widgets/playlist_card.dart';
import 'package:troona/features/playlist/presentation/widgets/playlist_mosaic.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

enum _PlaylistFilter { all, likesOnly, customOnly }

/// Redesigned Playlist Page with hero card for likes, grid/list toggle,
/// quick filters, and glassmorphic styling.
class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  bool _isGrid = true;
  _PlaylistFilter _filter = _PlaylistFilter.all;

  void _openCreateDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => BlocProvider.value(
          value: context.read<PlaylistBloc>(),
          child: const PlaylistEditorPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocListener<LikesCubit, LikesState>(
      listenWhen: (prev, curr) => prev.likedTrackIds != curr.likedTrackIds,
      listener: (context, _) {
        // Automatically sync playlist counts when likes change
        context.read<PlaylistBloc>().add(PlaylistListRequested());
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<PlaylistBloc, PlaylistState>(
            builder: (context, state) {
              if (state is PlaylistLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is PlaylistLoaded) {
                final playlists = state.playlists;

                // Split into Likes and Custom playlists
                Playlist? likesPlaylist;
                final customPlaylists = <Playlist>[];

                for (final p in playlists) {
                  if (p.id == IsarLibraryDataSource.likesPlaylistId) {
                    likesPlaylist = p;
                  } else {
                    customPlaylists.add(p);
                  }
                }

                // Apply filter
                final showHero =
                    likesPlaylist != null &&
                    _filter != _PlaylistFilter.customOnly;
                final showCustom = _filter != _PlaylistFilter.likesOnly;

                return CustomScrollView(
                  slivers: [
                    // ── Header Bar ───────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Playlists',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 28,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Grid / List View Toggle
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _isGrid
                                      ? LucideIcons.layoutList
                                      : LucideIcons.layoutGrid,
                                  color: Colors.white70,
                                  size: 19,
                                ),
                                tooltip: _isGrid ? 'Vue liste' : 'Vue grille',
                                onPressed: () =>
                                    setState(() => _isGrid = !_isGrid),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),

                            // + Create Playlist Pill
                            InkWell(
                              onTap: () => _openCreateDialog(context),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.accent,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.accent.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.plus,
                                      size: 15,
                                      color: Colors.black,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Créer',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Filter Chips ──────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'Toutes',
                              isSelected: _filter == _PlaylistFilter.all,
                              onTap: () =>
                                  setState(() => _filter = _PlaylistFilter.all),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Coups de cœur',
                              icon: LucideIcons.heart,
                              isSelected: _filter == _PlaylistFilter.likesOnly,
                              onTap: () => setState(
                                () => _filter = _PlaylistFilter.likesOnly,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Mes playlists',
                              icon: LucideIcons.listMusic,
                              isSelected: _filter == _PlaylistFilter.customOnly,
                              onTap: () => setState(
                                () => _filter = _PlaylistFilter.customOnly,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.md),
                    ),

                    // ── Hero Banner: Titres likés ─────────────────────────────
                    if (showHero) ...[
                      SliverToBoxAdapter(
                        child: LikesHeroCard(playlist: likesPlaylist),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.lg),
                      ),
                    ],

                    // ── Custom Playlists Section Header ───────────────────────
                    if (showCustom && customPlaylists.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'Vos playlists',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${customPlaylists.length}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── Playlists Body (Grid or List or Empty) ────────────────
                    if (showCustom)
                      if (customPlaylists.isEmpty)
                        SliverToBoxAdapter(
                          child: _EmptyPlaylistsView(
                            onCreate: () => _openCreateDialog(context),
                          ),
                        )
                      else if (_isGrid)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            AppSpacing.lg,
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 18,
                                  childAspectRatio: 0.77,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => PlaylistCard(
                                playlist: customPlaylists[index],
                              ),
                              childCount: customPlaylists.length,
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          sliver: SliverList.separated(
                            itemCount: customPlaylists.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) =>
                                _PlaylistTile(playlist: customPlaylists[index]),
                          ),
                        ),

                    // Bottom padding for mini-player
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                );
              }

              if (state is PlaylistError) {
                return Center(
                  child: Text(
                    'Erreur: ${state.message}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accent.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colors.accent.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? colors.accent : Colors.white60,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlaylistsView extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyPlaylistsView({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.glassFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.listPlus,
              color: Colors.white70,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Créez votre première playlist',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Rassemblez vos morceaux favoris selon vos envies et ambiances.',
            style: TextStyle(fontSize: 13, color: colors.labelSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Nouvelle playlist'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              shape: const StadiumBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  const _PlaylistTile({required this.playlist});

  void _showDeleteDialog(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Supprimer la playlist'),
        content: Text(
          'Voulez-vous vraiment supprimer "${playlist.name}" ? Cette action est irréversible.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PlaylistBloc>().add(
                PlaylistDeleteRequested(playlist.id),
              );
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLikes = playlist.id == IsarLibraryDataSource.likesPlaylistId;
    final trackCount = playlist.trackIds.length;
    final subtitle = trackCount == 1 ? '1 morceau' : '$trackCount morceaux';

    return InkWell(
      onTap: () => context.pushPlaylist(playlist.id),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isLikes
              ? const Color(0xFFB79CFF).withValues(alpha: 0.10)
              : colors.glassFill,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isLikes
                ? const Color(0xFFB79CFF).withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            // Artwork / Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: SizedBox.square(
                dimension: 58,
                child: isLikes
                    ? Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF382366), Color(0xFF1B1133)],
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.heart,
                          color: Color(0xFFB79CFF),
                          size: 26,
                        ),
                      )
                    : playlist.artworkPath != null
                    ? ArtworkImage(playlist.artworkPath!, width: 58, height: 58)
                    : playlist.trackIds.isNotEmpty
                    ? PlaylistMosaic(trackIds: playlist.trackIds, size: 58)
                    : Container(
                        color: Colors.white10,
                        child: const Icon(
                          LucideIcons.listMusic,
                          color: Colors.white30,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Info (Title & Track Count)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLikes ? 'Titres likés' : playlist.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.5,
                      color: isLikes ? Colors.white : Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isLikes
                          ? const Color(0xFFD4C4FF)
                          : colors.labelSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),

            // Trailing: Delete button for custom playlists, chevron for Likes
            if (!isLikes)
              IconButton(
                icon: const Icon(
                  LucideIcons.trash2,
                  size: 18,
                  color: Colors.white38,
                ),
                onPressed: () => _showDeleteDialog(context),
              )
            else
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 20,
                  color: Colors.white38,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
