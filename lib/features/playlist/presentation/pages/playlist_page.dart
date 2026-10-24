import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/playlist/presentation/bloc/playlist/playlist_bloc.dart';
import 'package:troona/features/playlist/presentation/pages/playlist_editor_page.dart';
import 'package:troona/features/playlist/presentation/widgets/playlist_mosaic.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';

class PlaylistPage extends StatelessWidget {
  const PlaylistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LikesCubit, LikesState>(
      listenWhen: (prev, curr) => prev.likedTrackIds != curr.likedTrackIds,
      listener: (context, _) {
        // Automatically sync playlist counts when likes change
        context.read<PlaylistBloc>().add(PlaylistListRequested());
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Playlists',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: GlassIconButton(
                icon: LucideIcons.plus,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (ctx) => BlocProvider.value(
                      value: context.read<PlaylistBloc>(),
                      child: const PlaylistEditorPage(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: BlocBuilder<PlaylistBloc, PlaylistState>(
          builder: (context, state) {
            if (state is PlaylistLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PlaylistLoaded) {
              final playlists = state.playlists;
              if (playlists.isEmpty) {
                return const Center(
                  child: Text(
                    'Aucune playlist pour le moment',
                    style: TextStyle(color: Colors.white30),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  120, // Avoid bottom bar overlap
                ),
                itemCount: playlists.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return _PlaylistTile(playlist: playlist);
                },
              );
            }

            if (state is PlaylistError) {
              return Center(child: Text('Erreur: ${state.message}'));
            }

            return const SizedBox.shrink();
          },
        ),
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
      onTap: () => context.pushNamed(
        AppRoute.playlistDetail,
        pathParameters: {'id': playlist.id},
      ),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isLikes
              ? const Color(0xFF450AF5).withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: .03),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isLikes
                ? const Color(0xFF450AF5).withValues(alpha: 0.3)
                : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            // Artwork / Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: SizedBox.square(
                dimension: 56,
                child: isLikes
                    ? Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF450AF5),
                              Color(0xFF8E8EE5),
                            ],
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.heart,
                          color: Colors.white,
                          size: 26,
                        ),
                      )
                    : playlist.artworkPath != null
                        ? ArtworkImage(
                            playlist.artworkPath!,
                            width: 56,
                            height: 56,
                          )
                        : playlist.trackIds.isNotEmpty
                            ? PlaylistMosaic(trackIds: playlist.trackIds)
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          isLikes ? 'Titres likés' : playlist.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isLikes
                                ? colors.labelPrimary
                                : Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isLikes) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF450AF5).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Favoris',
                            style: TextStyle(
                              color: Color(0xFF8E8EE5),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isLikes
                          ? const Color(0xFF8E8EE5).withValues(alpha: 0.8)
                          : Colors.white38,
                      fontSize: 13,
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
                  color: Colors.white24,
                ),
                onPressed: () => _showDeleteDialog(context),
              )
            else
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 20,
                  color: Colors.white24,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
