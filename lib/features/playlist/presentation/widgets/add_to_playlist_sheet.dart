import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:troona/features/playlist/presentation/bloc/playlist/playlist_bloc.dart';

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
        (list) => list
            .where((p) => p.id != IsarLibraryDataSource.likesPlaylistId)
            .toList(),
      );
    });
  }

  void _showCreateDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: const Color(0xFF222225),
        title: const Text('Nouvelle playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nom de la playlist',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(dlgCtx);
              final createRes = await getIt<PlaylistRepository>().createPlaylist(
                title: name,
              );
              createRes.fold((_) {}, (created) async {
                await getIt<PlaylistRepository>().addTrackToPlaylist(
                  created.id,
                  widget.track.id,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Morceau ajouté à "${created.name}"'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              });
            },
            child: const Text('Créer et ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _addTrackTo(Playlist playlist) async {
    final res = await getIt<PlaylistRepository>().addTrackToPlaylist(
      playlist.id,
      widget.track.id,
    );
    if (!mounted) return;
    Navigator.pop(context);

    res.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${f.message}')),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ajouté à "${playlist.name}"'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
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
                  const Text(
                    'Ajouter à la playlist',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),

            // Button "+ Nouvelle playlist"
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
              title: const Text(
                'Nouvelle playlist',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: _showCreateDialog,
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
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(
                        child: Text(
                          'Aucune playlist personnalisée créée',
                          style: TextStyle(color: Colors.white30),
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
                          '${p.trackIds.length} morceaux',
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
