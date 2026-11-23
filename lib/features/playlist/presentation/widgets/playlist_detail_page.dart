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
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/playlist/presentation/bloc/playlist_detail/playlist_detail_bloc.dart';
import 'package:troona/features/playlist/presentation/pages/smart_playlist_editor_page.dart';
import 'package:troona/features/playlist/presentation/widgets/playlist_cover.dart';
import 'package:troona/features/library/presentation/widgets/track_actions/show_track_actions.dart';
import 'package:troona/shared/widgets/app_dialog.dart';
import 'package:troona/shared/widgets/app_toast.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';
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
import 'package:troona/features/library/presentation/widgets/selection/selection_mark.dart';
import 'package:troona/features/library/presentation/widgets/selection/track_selection_scope.dart';
import 'package:troona/features/player/domain/entities/queue_origin.dart';

/// A playlist, laid out like an album: the cover over the palette glow, a
/// header that collapses into the glass bar, then the reorderable tracks.
/// A smart playlist's songs come from its rules: they cannot be moved or
/// removed, and its menu edits the rules or copies the songs into a
/// playlist.
List<Track>? _libraryTracksOf(LibraryState state) => switch (state) {
  LibraryLoaded(:final allTracks) => allTracks,
  LibraryScanning(:final cached?) => cached.allTracks,
  _ => null,
};

class PlaylistDetailPage extends StatelessWidget {
  final String id;
  const PlaylistDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LikesCubit, LikesState>(
          // Likes, and a smart playlist (its rules may ask for liked
          // songs), follow a song liked or unliked.
          listenWhen: (prev, curr) =>
              (id == Playlist.likesId || _showsSmart(context)) &&
              prev.likedTrackIds != curr.likedTrackIds,
          listener: (context, _) => context.read<PlaylistDetailBloc>().add(
            PlaylistDetailRequested(id),
          ),
        ),
        // A scan changes which of its songs the library shows: the rows,
        // and the places a move is counted in, must follow.
        BlocListener<LibraryBloc, LibraryState>(
          listenWhen: (previous, current) =>
              current is LibraryLoaded &&
              !identical(_libraryTracksOf(previous), current.allTracks),
          listener: (context, _) => context.read<PlaylistDetailBloc>().add(
            PlaylistDetailRequested(id),
          ),
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BlocBuilder<TrackPaletteCubit, TrackPaletteState>(
          builder: (_, palette) => DynamicBackground(
            colorA: palette.backgroundColorA,
            colorB: palette.backgroundColorB,
            tone: DynamicBackgroundTone.immersive,
            child: BlocBuilder<PlaylistDetailBloc, PlaylistDetailState>(
              // A long press on a song picks songs of the playlist. Above
              // the states: a reload keeps the songs picked.
              builder: (context, state) => TrackSelectionScope(
                tracks: switch (state) {
                  PlaylistDetailLoaded(:final data) => data.tracks,
                  _ => const [],
                },
                child: switch (state) {
                  PlaylistDetailLoaded(:final data) => CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      _PlaylistHeader(
                        playlist: data.playlist,
                        name: _nameOf(context, data.playlist),
                        tracks: data.tracks,
                      ),
                      _TrackList(
                        playlist: data.playlist,
                        tracks: data.tracks,
                        origin: _originOf(context, data.playlist),
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
      actions: [
        if (playlist.isSmart)
          GlassIconButton(
            icon: AppIcons.moreVertical,
            tooltip: context.l10n.detailMore,
            onTap: () => _showSmartActions(context, playlist, tracks),
          ),
      ],
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
                      // Marked, as on an album: the bar takes the name
                      // over when this one goes under it.
                      child: GlassHeaderTitle(
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
                    ),
                    1,
                  ),
                  const SizedBox(height: 8),
                  _staggered(
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (playlist.isSmart)
                          AppBadge.accent(context.l10n.smartBadge),
                        AppBadge(
                          tracks.isEmpty
                              ? context.l10n.songCount(0)
                              : context.l10n.detailCountsSummary(
                                  context.l10n.songCount(tracks.length),
                                  duration.toHumanReadable(context.l10n),
                                ),
                        ),
                      ],
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
              child: PlayShuffleButtons(
                tracks: tracks,
                origin: _originOf(context, playlist),
              ),
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
  final Playlist playlist;
  final List<Track> tracks;
  final QueueOrigin origin;

  const _TrackList({
    required this.playlist,
    required this.tracks,
    required this.origin,
  });

  @override
  Widget build(BuildContext context) {
    final playlistId = playlist.id;
    final isLikes = playlistId == Playlist.likesId;
    if (tracks.isEmpty && playlist.isSmart) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: AppIcons.smartPlaylist,
          title: context.l10n.smartEmptyTitle,
          body: context.l10n.smartEmptyBody,
          actionLabel: context.l10n.smartPlaylistEdit,
          onAction: () => _editRules(context, playlist),
        ),
      );
    }
    if (playlist.isSmart) {
      // Its rules set the songs and their order: no handle, no reorder.
      return SliverList.builder(
        itemCount: tracks.length,
        itemBuilder: (context, index) => _TrackTile(
          key: ValueKey(tracks[index].id),
          track: tracks[index],
          tracks: tracks,
          playlistId: playlistId,
          index: index,
          isLikes: false,
          smart: true,
          origin: origin,
        ),
      );
    }
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
          origin: origin,
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

  /// A song a smart playlist's rules keep: the song's own menu, since it
  /// cannot be removed, and no handle.
  final bool smart;
  final QueueOrigin origin;

  const _TrackTile({
    super.key,
    required this.track,
    required this.tracks,
    required this.playlistId,
    required this.index,
    required this.isLikes,
    this.smart = false,
    required this.origin,
  });

  void _showTrackOptions(BuildContext context) {
    if (smart) {
      showTrackActions(context, track);
      return;
    }
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
    final (picking, selected) = TrackSelectionScope.statusOf(context, track.id);
    final hints = TrackSelectionScope.hintsOf(
      context,
      picking: picking,
      selected: selected,
    );

    // A long press picks songs, as in every list of songs: the handle alone
    // moves a row.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: selected
          ? colors.accent.withValues(alpha: .12)
          : colors.accent.withValues(alpha: 0),
      child: Material(
        color: Colors.transparent,
        child: Semantics(
          selected: picking ? selected : null,
          onTapHint: hints.tap,
          onLongPressHint: hints.longPress,
          child: InkWell(
            onLongPress: () => TrackSelectionScope.longPress(context, track),
            // The pick ticks on its own: no system buzz on top.
            enableFeedback: false,
            onTap: () {
              if (TrackSelectionScope.tap(context, track)) return;
              context.read<PlayerBloc>().add(
                PlayTrackRequested(
                  track,
                  contextQueue: tracks,
                  contextIndex: index,
                  origin: origin,
                ),
              );
            },
            highlightColor: colors.pressedInk,
            splashColor: colors.pressedInk,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      TrackRowArtwork(track: track),
                      Positioned.fill(
                        child: SelectionMark(
                          picking: picking,
                          selected: selected,
                          radius: TrackRowArtwork.radius,
                        ),
                      ),
                    ],
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

                  // Options (remove) and the handle, gone while picking:
                  // their room is kept, so nothing moves.
                  IgnorePointer(
                    ignoring: picking,
                    child: AnimatedOpacity(
                      opacity: picking ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIconButton(
                            icon: AppIcons.more,
                            tooltip: context.l10n.detailMore,
                            size: 18,
                            color: context.colors.labelSecondary,
                            onPressed: () => _showTrackOptions(context),
                          ),
                          if (!smart)
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Whether the page shows a smart playlist.
bool _showsSmart(BuildContext context) =>
    switch (context.read<PlaylistDetailBloc>().state) {
      PlaylistDetailLoaded(:final data) => data.playlist.isSmart,
      _ => false,
    };

/// The playlist's name as its page shows it: Liked songs in the app's
/// language.
String _nameOf(BuildContext context, Playlist playlist) =>
    playlist.id == Playlist.likesId ? context.l10n.likedSongs : playlist.name;

/// The playlist a queue started on its page comes from, for Home's resume
/// card.
QueueOrigin _originOf(BuildContext context, Playlist playlist) => QueueOrigin(
  QueueOriginKind.playlist,
  id: playlist.id,
  name: _nameOf(context, playlist),
);

/// A smart playlist's menu: edit its rules, or copy its songs into a
/// playlist (only once it has some).
void _showSmartActions(
  BuildContext context,
  Playlist playlist,
  List<Track> tracks,
) {
  final l10n = context.l10n;
  showActionSheet(
    context,
    title: playlist.name,
    actions: [
      SheetAction(
        label: l10n.smartPlaylistEdit,
        icon: AppIcons.smartRule,
        onPressed: () => _editRules(context, playlist),
      ),
      if (tracks.isNotEmpty)
        SheetAction(
          label: l10n.smartSaveAsPlaylist,
          icon: AppIcons.addToPlaylist,
          onPressed: () => _saveAsPlaylist(context, playlist),
        ),
    ],
  );
}

/// Opens the rules' editor, then reads the songs again once saved.
Future<void> _editRules(BuildContext context, Playlist playlist) async {
  final bloc = context.read<PlaylistDetailBloc>();
  final saved = await openSmartPlaylistEditor(context, playlist);
  if (saved != null && !bloc.isClosed) {
    bloc.add(PlaylistDetailRequested(playlist.id));
  }
}

/// Asks a name, then copies the songs shown, in their order, into a new
/// playlist of songs: a snapshot that no longer follows the rules.
Future<void> _saveAsPlaylist(BuildContext context, Playlist playlist) async {
  final l10n = context.l10n;
  final bloc = context.read<PlaylistDetailBloc>();
  final name = await showTextInputDialog(
    context,
    title: l10n.smartSaveAsPlaylist,
    placeholder: l10n.playlistNameHint,
    confirmLabel: l10n.actionSave,
    initialValue: playlist.name,
  );
  if (name == null || name.trim().isEmpty || bloc.isClosed) return;
  bloc.add(
    PlaylistSaveAsRequested(
      name,
      onSaved: (saved) {
        if (context.mounted) {
          AppToast.show(context, l10n.smartSavedAsPlaylist(saved.name));
        }
      },
      onFailed: () {
        if (context.mounted) AppToast.show(context, l10n.errorGeneric);
      },
    ),
  );
}
