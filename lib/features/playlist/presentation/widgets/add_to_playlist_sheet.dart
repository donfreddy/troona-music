import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:troona/shared/widgets/app_dialog.dart';
import 'package:troona/shared/widgets/app_toast.dart';

Future<void> showAddToPlaylistSheet(BuildContext context, Track track) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF161618),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _AddToPlaylistView(track: track),
  );
}

class _AddToPlaylistView extends StatefulWidget {
  final Track track;
  const _AddToPlaylistView({required this.track});

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
        (list) => list.where((p) => p.id != Playlist.likesId).toList(),
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
    await _addTrackTo(created);
  }

  Future<void> _addTrackTo(Playlist playlist) async {
    final l10n = context.l10n;
    final repo = getIt<PlaylistRepository>();
    final trackId = widget.track.id;
    final res = await repo.addTrackToPlaylist(playlist.id, trackId);
    if (!mounted) return;
    // The toast outlives the sheet: grab the root overlay before closing it.
    final overlay = Overlay.of(context, rootOverlay: true);
    Navigator.pop(context);

    res.fold(
      (_) => AppToast.showOn(overlay, l10n.errorGeneric),
      (_) => AppToast.showOn(
        overlay,
        l10n.playlistAddedTo(playlist.name),
        actionLabel: l10n.actionUndo,
        onAction: () => repo.removeTrackFromPlaylist(playlist.id, trackId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white54),
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
                child: Icon(LucideIcons.plus, color: colors.accent),
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
                    return const Center(
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
                      final alreadyIn = p.trackIds.contains(widget.track.id);

                      return ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            LucideIcons.listMusic,
                            color: Colors.white30,
                          ),
                        ),
                        title: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          context.l10n.songCount(p.trackIds.length),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                        trailing: alreadyIn
                            ? Icon(
                                LucideIcons.check,
                                color: colors.accent,
                                size: 18,
                              )
                            : null,
                        onTap: alreadyIn ? null : () => _addTrackTo(p),
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
