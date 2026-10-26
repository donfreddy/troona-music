import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:troona/shared/widgets/error_view.dart';
import 'package:troona/shared/widgets/empty_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/playlist/presentation/bloc/playlist_detail/playlist_detail_bloc.dart';
import 'package:troona/features/playlist/presentation/widgets/playlist_mosaic.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';
import 'package:troona/core/extensions/context_ext.dart';

class PlaylistDetailPage extends StatelessWidget {
  final String id;
  const PlaylistDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LikesCubit, LikesState>(
      listenWhen: (prev, curr) =>
          id == IsarLibraryDataSource.likesPlaylistId &&
          prev.likedTrackIds != curr.likedTrackIds,
      listener: (context, _) {
        // Automatically sync Likes playlist when a track is liked/unliked
        context.read<PlaylistDetailBloc>().add(PlaylistDetailRequested(id));
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocBuilder<PlaylistDetailBloc, PlaylistDetailState>(
          builder: (context, state) {
            if (state is PlaylistDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PlaylistDetailLoaded) {
              final data = state.data;
              final isLikes = id == IsarLibraryDataSource.likesPlaylistId;

              return CustomScrollView(
                slivers: [
                  _SliverHeader(
                    id: id,
                    name: isLikes
                        ? context.l10n.likedSongs
                        : data.playlist.name,
                    tracks: data.tracks,
                    artworkPath: data.playlist.artworkPath,
                    isLikes: isLikes,
                  ),
                  _TrackList(
                    playlistId: id,
                    tracks: data.tracks,
                    isLikes: isLikes,
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              );
            }

            if (state is PlaylistDetailError) {
              return ErrorView(
                body: context.l10n.playlistOpenError,
                onRetry: () => context.read<PlaylistDetailBloc>().add(
                  PlaylistDetailRequested(id),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _SliverHeader extends StatelessWidget {
  final String id;
  final String name;
  final List<Track> tracks;
  final String? artworkPath;
  final bool isLikes;

  const _SliverHeader({
    required this.id,
    required this.name,
    required this.tracks,
    required this.artworkPath,
    required this.isLikes,
  });

  void _onPlay(BuildContext context) {
    if (tracks.isEmpty) return;
    context.read<PlayerBloc>().add(
      PlayTrackRequested(tracks[0], contextQueue: tracks, contextIndex: 0),
    );
  }

  void _onShuffle(BuildContext context) {
    if (tracks.isEmpty) return;
    final bloc = context.read<PlayerBloc>();
    final alreadyShuffled = switch (bloc.state) {
      PlayerActive(:final shuffleEnabled) => shuffleEnabled,
      _ => false,
    };
    final shuffled = List<Track>.from(tracks)..shuffle();
    bloc.add(
      PlayTrackRequested(shuffled[0], contextQueue: shuffled, contextIndex: 0),
    );
    // A toggle: sending it while shuffle is on would turn it off.
    if (!alreadyShuffled) bloc.add(const ShuffleToggleRequested());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final trackCount = tracks.length;
    final countLabel = context.l10n.songCount(trackCount);

    return SliverAppBar(
      expandedHeight: 330,
      pinned: true,
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
            // Background gradient
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isLikes
                      ? [
                          const Color(0xFFB79CFF).withValues(alpha: 0.32),
                          const Color(0xFF1E1338).withValues(alpha: 0.20),
                          Colors.black,
                        ]
                      : [
                          colors.accent.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.8),
                          Colors.black,
                        ],
                ),
              ),
            ),

            SafeArea(
              bottom: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  // Cover container
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: isLikes
                              ? const Color(0xFFB79CFF).withValues(alpha: 0.30)
                              : Colors.black.withValues(alpha: 0.6),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: isLikes
                          ? Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF382366),
                                    Color(0xFF1F133B),
                                    Color(0xFF0D0819),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.heart,
                                color: Color(0xFFB79CFF),
                                size: 64,
                              ),
                            )
                          : artworkPath != null
                          ? ArtworkImage(artworkPath!)
                          : PlaylistMosaic(
                              trackIds: tracks.map((t) => t.id).toList(),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    countLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Actions row: Play and Shuffle
                  if (tracks.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _onPlay(context),
                          icon: const Icon(LucideIcons.play, size: 18),
                          label: Text(context.l10n.actionPlay),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.accent,
                            foregroundColor: Colors.black,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.sm,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        IconButton.filledTonal(
                          onPressed: () => _onShuffle(context),
                          icon: const Icon(LucideIcons.shuffle, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white12,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
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
  final bool isLikes;

  const _TrackList({
    required this.playlistId,
    required this.tracks,
    required this.isLikes,
  });

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: isLikes ? LucideIcons.heart : LucideIcons.listMusic,
          title: isLikes
              ? context.l10n.likesEmptyTitle
              : context.l10n.playlistEmptyTitle,
          body: isLikes
              ? context.l10n.likesEmptyBody
              : context.l10n.playlistEmptyBody,
        ),
      );
    }

    return SliverReorderableList(
      itemCount: tracks.length,
      onReorderItem: (oldIndex, newIndex) {
        context.read<PlaylistDetailBloc>().add(
          PlaylistReorderTracksRequested(playlistId, oldIndex, newIndex),
        );
      },
      itemBuilder: (context, index) {
        final track = tracks[index];
        return _TrackTile(
          key: ValueKey(track.id),
          track: track,
          tracks: tracks,
          playlistId: playlistId,
          index: index,
          isLikes: isLikes,
        );
      },
    );
  }
}

class _TrackTile extends StatelessWidget {
  final Track track;
  final List<Track> tracks;
  final String playlistId;
  final int index;
  final bool isLikes;

  const _TrackTile({
    super.key,
    required this.track,
    required this.tracks,
    required this.playlistId,
    required this.index,
    required this.isLikes,
  });

  void _showTrackOptions(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(track.title),
        message: Text(track.artist),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              if (isLikes) {
                context.read<LikesCubit>().toggle(track);
              } else {
                context.read<PlaylistDetailBloc>().add(
                  PlaylistRemoveTrackRequested(playlistId, track.id),
                );
              }
            },
            child: Text(
              isLikes ? context.l10n.likesRemove : context.l10n.playlistRemove,
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(context.l10n.actionCancel),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isActive = context.select<PlayerBloc, bool>(
      (b) =>
          b.state is PlayerActive &&
          (b.state as PlayerActive).currentTrack.id == track.id,
    );

    return ReorderableDelayedDragStartListener(
      index: index,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.read<PlayerBloc>().add(
              PlayTrackRequested(
                track,
                contextQueue: tracks,
                contextIndex: index,
              ),
            );
          },
          highlightColor: colors.glassHighlight,
          splashColor: colors.glassHighlight,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                // Artwork thumbnail
                SizedBox.square(
                  dimension: 48,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: track.artworkPath != null
                            ? ArtworkImage(
                                track.artworkPath!,
                                width: 48,
                                height: 48,
                              )
                            : Container(
                                color: Colors.white.withValues(alpha: .08),
                                child: const Icon(
                                  LucideIcons.music,
                                  color: Colors.white30,
                                ),
                              ),
                      ),
                      if (isActive)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: .5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              LucideIcons.music2,
                              color: colors.accent,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: AppSpacing.md),

                // Info track
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        style: TextStyle(
                          color: isActive ? colors.accent : Colors.white,
                          fontSize: 15,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track.artist,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .5),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Options (remove) button
                IconButton(
                  icon: const Icon(
                    LucideIcons.ellipsis,
                    size: 20,
                    color: Colors.white38,
                  ),
                  onPressed: () => _showTrackOptions(context),
                ),

                // Drag handle
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      LucideIcons.gripVertical,
                      size: 20,
                      color: Colors.white24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
