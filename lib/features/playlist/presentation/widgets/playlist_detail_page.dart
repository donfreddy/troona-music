import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/core/theme/components/glass_filter.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
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
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/shared/widgets/dynamic_background.dart';
import 'package:troona/shared/widgets/empty_state.dart';
import 'package:troona/shared/widgets/entrance_fader.dart';
import 'package:troona/shared/widgets/error_view.dart';
import 'package:troona/shared/widgets/app_badge.dart';
import 'package:troona/features/player/presentation/widgets/play_shuffle_buttons.dart';
import 'package:troona/shared/widgets/app_back_button.dart';

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
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _PlaylistHeroDelegate(
                        playlist: data.playlist,
                        name: id == Playlist.likesId
                            ? context.l10n.likedSongs
                            : data.playlist.name,
                        tracks: data.tracks,
                        topPadding: MediaQuery.of(context).padding.top,
                        textScale: MediaQuery.textScalerOf(context).scale(1),
                      ),
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
class _PlaylistHeroDelegate extends SliverPersistentHeaderDelegate {
  final Playlist playlist;
  final String name;
  final List<Track> tracks;
  final double topPadding;

  /// The phone's font size: the expanded header grows with its text.
  final double textScale;

  const _PlaylistHeroDelegate({
    required this.playlist,
    required this.name,
    required this.tracks,
    required this.topPadding,
    required this.textScale,
  });

  static const double _navBarHeight = 44.0;
  static const double _actionsBarHeight = 64.0;

  /// Height of the expanded header's text at the default font size.
  static const double _expandedText = 100.0;
  static const double _expandedExtra = 290.0;
  static const double _coverSize = 180.0;

  @override
  double get minExtent => topPadding + _navBarHeight + _actionsBarHeight;

  @override
  double get maxExtent =>
      topPadding +
      _navBarHeight +
      _expandedExtra +
      (textScale - 1) * _expandedText +
      _actionsBarHeight;

  @override
  bool shouldRebuild(_PlaylistHeroDelegate old) =>
      old.playlist != playlist ||
      old.name != name ||
      old.tracks != tracks ||
      old.topPadding != topPadding ||
      old.textScale != textScale;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final collapse = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final colors = context.colors;
    // Same glass as the Library's collapsed header.
    final glass = GlassTheme.bar(context);
    final blurSigma = glass.blurSigma * collapse;
    final duration = Duration(
      milliseconds: tracks.fold<int>(0, (sum, t) => sum + t.durationMs),
    );

    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: Color.lerp(Colors.transparent, glass.fill, collapse),
        border: Border(
          bottom: BorderSide(
            color: colors.separator.withValues(alpha: collapse),
            width: 0.5,
          ),
        ),
      ),
      child: SizedBox(
        height: (maxExtent - shrinkOffset).clamp(minExtent, maxExtent),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // ── Expanded content: cover, title, counts ──────────────────
            Positioned(
              top: topPadding + _navBarHeight,
              left: 0,
              right: 0,
              bottom: _actionsBarHeight,
              child: Opacity(
                opacity: (1 - collapse * 1.6).clamp(0.0, 1.0),
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
            ),

            // ── Top navigation bar ──────────────────────────────────────
            Positioned(
              top: topPadding,
              left: 0,
              right: 0,
              height: _navBarHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: collapse,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Positioned(left: 0, child: const AppBackButton()),
                  ],
                ),
              ),
            ),

            // ── Play and shuffle ────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
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
      ),
    );

    return RepaintBoundary(
      child: ClipRect(
        child: blurSigma > 0
            ? BackdropFilter(
                filter: GlassFilter.of(blurSigma, saturation: glass.saturation),
                child: content,
              )
            : content,
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
    showActionSheet(
      context,
      title: track.title,
      message: track.artist,
      actions: [
        SheetAction(
          label: isLikes
              ? context.l10n.likesRemove
              : context.l10n.playlistRemove,
          icon: isLikes ? LucideIcons.heartOff : LucideIcons.listX,
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
              horizontal: AppSpacing.lg,
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
                  icon: LucideIcons.ellipsis,
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
