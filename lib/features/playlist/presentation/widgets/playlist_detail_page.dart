import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/playlist/presentation/bloc/playlist_detail/playlist_detail_bloc.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';

class PlaylistDetailPage extends StatelessWidget {
  final String id;
  const PlaylistDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<PlaylistDetailBloc, PlaylistDetailState>(
        builder: (context, state) {
          if (state is PlaylistDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PlaylistDetailLoaded) {
            final data = state.data;
            return CustomScrollView(
              slivers: [
                _SliverHeader(id: id, name: data.playlist.name, description: data.playlist.name),
                _TrackList(playlistId: id, tracks: data.tracks),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            );
          }

          if (state is PlaylistDetailError) {
            return Center(child: Text('Erreur: ${state.message}'));
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SliverHeader extends StatelessWidget {
  final String id;
  final String name;
  final String? description;
  const _SliverHeader({required this.id, required this.name, this.description});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      backgroundColor: Colors.black,
      leadingWidth: 70,
      leading: Center(
        child: GlassIconButton(
          icon: LucideIcons.chevronLeft,
          onTap: () => context.pop(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.purple.withValues(alpha: .2), Colors.black],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.xl2),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: .5), blurRadius: 20, spreadRadius: 5),
                      ],
                    ),
                    child: const Icon(LucideIcons.listMusic, size: 64, color: Colors.white24),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  if (description != null)
                    Text(description!, style: const TextStyle(color: Colors.white30)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackList extends StatelessWidget {
  final String playlistId;
  final List<Track> tracks;
  const _TrackList({required this.playlistId, required this.tracks});

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('Aucun morceau dans cette playlist', style: TextStyle(color: Colors.white30))),
      );
    }

    return SliverReorderableList(
      itemCount: tracks.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex -= 1;
        context.read<PlaylistDetailBloc>().add(PlaylistReorderTracksRequested(playlistId, oldIndex, newIndex));
      },
      itemBuilder: (context, index) {
        final track = tracks[index];
        return _TrackTile(key: ValueKey(track.id), track: track, playlistId: playlistId, index: index);
      },
    );
  }
}

class _TrackTile extends StatelessWidget {
  final Track track;
  final String playlistId;
  final int index;
  const _TrackTile({super.key, required this.track, required this.playlistId, required this.index});

  @override
  Widget build(BuildContext context) {
    return ReorderableDelayedDragStartListener(
      index: index,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: () {
            // context.read<PlayerBloc>().add(
            //   PlayerPlaylistRequested(
            //     playlist: tracksFromEntity(context.read<PlaylistDetailBloc>().state),
            //     initialIndex: index,
            //   ),
            // );
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: const Icon(LucideIcons.music, size: 20, color: Colors.white30),
          ),
          title: Text(track.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(track.artist, style: const TextStyle(color: Colors.white30, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // IconButton(
              //   icon:  Icon(LucideIcons.ecliv, size: 18, color: Colors.white24),
              //   onPressed: () {
              //     // Afficher les options (Supprimer de la playlist)
              //     _showTrackOptions(context);
              //   },
              // ),
              const ReorderableDragStartListener(
                index: 0, // Ignored here as we use ReorderableDelayedDragStartListener
                child: Icon(LucideIcons.gripVertical, size: 20, color: Colors.white12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrackOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(LucideIcons.trash2, color: Colors.redAccent),
            title: const Text('Retirer de la playlist', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              context.read<PlaylistDetailBloc>().add(PlaylistRemoveTrackRequested(playlistId, track.id as int));
              Navigator.pop(ctx);
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  List<Track> tracksFromEntity(PlaylistDetailState state) {
    if (state is PlaylistDetailLoaded) return state.data.tracks;
    return [];
  }
}
