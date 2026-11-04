import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/playlist/presentation/bloc/playlist_detail/playlist_detail_bloc.dart';
import 'package:troona/features/playlist/presentation/widgets/playlist_cover.dart';
import 'package:troona/shared/widgets/action_sheet.dart';
import 'package:troona/shared/widgets/app_icon_button.dart';
import 'package:troona/shared/widgets/dynamic_background.dart';
import 'package:troona/shared/widgets/empty_state.dart';
import 'package:troona/shared/widgets/entrance_fader.dart';
import 'package:troona/shared/widgets/error_view.dart';
import 'package:troona/shared/widgets/app_badge.dart';
import 'package:troona/features/player/presentation/widgets/play_shuffle_buttons.dart';
import 'package:troona/shared/widgets/app_back_button.dart';
import 'package:troona/shared/widgets/glass_sliver_header.dart';
import 'package:troona/features/library/presentation/widgets/track_row_artwork.dart';

/// A playlist, laid out like an album: the cover over the palette glow, a
/// header that collapses into the glass bar, then the reorderable tracks.
class PlaylistDetailPage extends StatelessWidget {
  final String id;
  const PlaylistDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LikesCubit, LikesState>(
      listenWhen: (prev, curr) =>
          id == Playlist.likesId && prev.likedTrackIds != curr.likedTrackIds,
      listener: (context, _) {
        // Automatically sync Likes playlist when a track is liked/unliked
        context.read<PlaylistDetailBloc>().add(PlaylistDetailRequested(id));
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BlocBuilder<TrackPaletteCubit, TrackPaletteState>(
          builder: (_, palette) => DynamicBackground(
            colorA: palette.backgroundColorA,
            colorB: palette.backgroundColorB,
            tone: DynamicBackgroundTone.immersive,
            child: BlocBuilder<PlaylistDetailBloc, PlaylistDetailState>(
              builder: (context, state) => switch (state) {
                PlaylistDetailLoaded(:final data) => CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    _PlaylistHeader(
                      playlist: data.playlist,
                      name: id == Playlist.likesId
                          ? context.l10n.likedSongs
                          : data.playlist.name,
                      tracks: data.tracks,
                    ),
                    _TrackList(
                      playlistId: id,
                      tracks: data.tracks,
                      isLikes: id == Playlist.likesId,
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: context.bottomBarInset(tabs: false),
                      ),
                    ),
                  ],
                ),
                PlaylistDetailError() => ErrorView(
                  body: context.l10n.playlistOpenError,
                  onRetry: () => context.read<PlaylistDetailBloc>().add(
                    PlaylistDetailRequested(id),
                  ),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Same header as the album page: the expanded cover and titles fade out
/// as it collapses into the glass bar, which takes the title.
class _PlaylistHeader extends StatelessWidget {
  final Playlist playlist;
  final String name;
  final List<Track> tracks;

  const _PlaylistHeader({
    required this.playlist,
    required this.name,
    required this.tracks,
  });

  static const double _actionsBarHeight = 64.0;

  /// Height of the expanded header's text at the default font size.
  static const double _expandedText = 100.0;
  static const double _expandedExtra = 290.0;
  static const double _coverSize = 180.0;

  @override
  Widget build(BuildContext context) {
    final duration = Duration(
      milliseconds: tracks.fold<int>(0, (sum, t) => sum + t.durationMs),
    );

    return GlassSliverHeader(
      leading: const AppBackButton(),
      title: name,
      actions: const [],
      expandedHeight: _expandedExtra + _actionsBarHeight,
      expandedTextHeight: _expandedText,
      expanded: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  _staggered(
                    Container(
                      width: _coverSize,
                      height: _coverSize,
                      // Depth only, like the album cover.
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: PlaylistCover(
                          playlist: playlist,
                          size: _coverSize,
                        ),
                      ),
                    ),
                    0,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _staggered(
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    1,
                  ),
                  const SizedBox(height: 8),
                  _staggered(
                    AppBadge(
                      tracks.isEmpty
                          ? context.l10n.songCount(0)
                          : context.l10n.detailCountsSummary(
                              context.l10n.songCount(tracks.length),
                              duration.toHumanReadable(context.l10n),
                            ),
                    ),
                    2,
                  ),
                ],
              ),
            ),
          ),
          // Play and shuffle scroll away with the hero: the collapsed bar
          // keeps the title and actions only.
          SizedBox(
            height: _actionsBarHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 8,
              ),
              child: PlayShuffleButtons(tracks: tracks),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _staggered(Widget child, int index) => EntranceFader.staggered(
    index: index,
    stepMs: 22,
    slideY: 0.15,
    child: child,
  );
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
          icon: isLikes ? AppIcons.like : AppIcons.playlist,
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
    showActionSheet(
      context,
      title: track.title,
      message: context.artistName(track.artist),
      actions: [
        SheetAction(
          label: isLikes
              ? context.l10n.likesRemove
              : context.l10n.playlistRemove,
          icon: isLikes ? AppIcons.unlike : AppIcons.removeFromList,
          destructive: true,
          onPressed: () {
            if (isLikes) {
              context.read<LikesCubit>().toggle(track);
            } else {
              context.read<PlaylistDetailBloc>().add(
                PlaylistRemoveTrackRequested(playlistId, track.id),
              );
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (isActive, _) = TrackRowArtwork.statusOf(context, track.id);

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
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                TrackRowArtwork(track: track),

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
                              : FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.artistName(track.artist),
                        style: TextStyle(
                          color: colors.labelSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Options (remove) button
                AppIconButton(
                  icon: AppIcons.more,
                  tooltip: context.l10n.detailMore,
                  size: 18,
                  color: context.colors.labelTertiary,
                  onPressed: () => _showTrackOptions(context),
                ),

                // Drag handle
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      AppIcons.dragHandle,
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
