import 'package:flutter/material.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:troona/shared/widgets/app_dialog.dart';
import 'package:troona/shared/widgets/app_icon_button.dart';
import 'package:troona/shared/widgets/app_toast.dart';
import 'package:troona/shared/widgets/glass_bottom_sheet.dart';

/// Lists the playlists [track] can go to, above the mini player and the
/// tab bar. Many playlists scroll.
Future<void> showAddToPlaylistSheet(BuildContext context, Track track) =>
    showAddTracksToPlaylistSheet(context, [track]);

/// Lists the playlists [tracks] can go to. A playlist takes the ones it
/// does not hold yet, in their order; one that holds them all is checked.
/// Completes with whether songs were added.
Future<bool> showAddTracksToPlaylistSheet(
  BuildContext context,
  List<Track> tracks,
) async {
  final added = await showGlassBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // List tiles carry their own side padding; the view keeps clear of the
    // bottom inset itself.
    padding: EdgeInsets.zero,
    builder: (ctx) => _AddToPlaylistView(tracks: tracks),
  );
  return added ?? false;
}

/// The ids of [tracks] that [playlist] does not hold yet, in order, each
/// once.
@visibleForTesting
List<String> missingTrackIds(Playlist playlist, List<Track> tracks) {
  final held = {...playlist.trackIds};
  return [
    for (final track in tracks)
      if (held.add(track.id)) track.id,
  ];
}

class _AddToPlaylistView extends StatefulWidget {
  final List<Track> tracks;
  const _AddToPlaylistView({required this.tracks});

  @override
  State<_AddToPlaylistView> createState() => _AddToPlaylistViewState();
}

class _AddToPlaylistViewState extends State<_AddToPlaylistView> {
  late Future<List<Playlist>> _playlistsFuture;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  void _loadPlaylists() {
    _playlistsFuture = getIt<PlaylistRepository>().getPlaylists().then((res) {
      return res.fold(
        (_) => <Playlist>[],
        // A smart playlist's songs come from its rules: none can be added.
        (list) =>
            list.where((p) => p.id != Playlist.likesId && !p.isSmart).toList(),
      );
    });
  }

  Future<void> _createAndAdd() async {
    final l10n = context.l10n;
    final name = await showTextInputDialog(
      context,
      title: l10n.playlistNew,
      placeholder: l10n.playlistNameHint,
      confirmLabel: l10n.playlistCreateAndAdd,
    );
    if (name == null || !mounted) return;
    final repo = getIt<PlaylistRepository>();
    final created = (await repo.createPlaylist(
      title: name,
    )).toOption().toNullable();
    if (!mounted) return;
    if (created == null) {
      final overlay = Overlay.of(context, rootOverlay: true);
      Navigator.pop(context);
      AppToast.showOn(overlay, l10n.errorGeneric);
      return;
    }
    await _addTracksTo(created);
  }

  Future<void> _addTracksTo(Playlist playlist) async {
    final l10n = context.l10n;
    final repo = getIt<PlaylistRepository>();
    // One write, all or none: the songs it lacks, in their order.
    final res = await repo.addTracksToPlaylist(
      playlist.id,
      missingTrackIds(playlist, widget.tracks),
    );
    if (!mounted) return;
    // The toast outlives the sheet: grab the root overlay before closing it.
    final overlay = Overlay.of(context, rootOverlay: true);
    final added = res.getOrElse(() => const []);
    // Only songs added end a selection: after a failure they stay picked
    // for another try.
    Navigator.pop(context, added.isNotEmpty);

    if (res.isLeft()) {
      AppToast.showOn(overlay, l10n.errorGeneric);
      return;
    }
    // Nothing was missing: the row is off then.
    if (added.isEmpty) return;
    AppToast.showOn(
      overlay,
      added.length == 1
          ? l10n.playlistAddedTo(playlist.name)
          : l10n.playlistAddedSongsTo(added.length, playlist.name),
      actionLabel: l10n.actionUndo,
      onAction: () => repo.removeTracksFromPlaylist(playlist.id, added),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Its own Material: the sheet's glass would hide the rows' ink.
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.playlistAddTo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  AppIconButton(
                    icon: AppIcons.close,
                    tooltip: context.l10n.actionClose,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),

            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(AppIcons.add, color: colors.accent),
              ),
              title: Text(
                context.l10n.playlistNew,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: _createAndAdd,
            ),

            const SizedBox(height: 4),

            // Playlists list
            Flexible(
              child: FutureBuilder<List<Playlist>>(
                future: _playlistsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Shrink-wrapped: the sheet only grows with its list.
                    return const Center(
                      heightFactor: 1,
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final playlists = snapshot.data ?? [];
                  if (playlists.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Center(
                        heightFactor: 1,
                        child: Text(
                          context.l10n.playlistNoneYet,
                          style: const TextStyle(color: Colors.white38),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final p = playlists[index];
                      final alreadyIn = missingTrackIds(
                        p,
                        widget.tracks,
                      ).isEmpty;

                      return ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            AppIcons.playlist,
                            color: Colors.white30,
                          ),
                        ),
                        title: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          context.l10n.songCount(p.songCount),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                        trailing: alreadyIn
                            ? Icon(
                                AppIcons.selected,
                                color: colors.accent,
                                size: 18,
                              )
                            : null,
                        onTap: alreadyIn ? null : () => _addTracksTo(p),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
