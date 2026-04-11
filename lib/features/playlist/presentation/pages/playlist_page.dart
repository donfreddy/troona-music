import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/playlist/presentation/bloc/playlist/playlist_bloc.dart';
import 'package:troona/features/playlist/presentation/pages/playlist_editor_page.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';

class PlaylistPage extends StatelessWidget {
  const PlaylistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: playlists.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
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
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  const _PlaylistTile({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.pushNamed(
        AppRoute.playlistDetail,
        pathParameters: {'id': playlist.id},
      ),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .03),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(LucideIcons.listMusic, color: Colors.white30),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (playlist.name.isNotEmpty)
                    Text(
                      playlist.name,
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    '${playlist.trackIds.length} morceaux',
                    style: const TextStyle(color: Colors.white30, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: Colors.white24,
            ),
          ],
        ),
      ),
    );
  }
}
