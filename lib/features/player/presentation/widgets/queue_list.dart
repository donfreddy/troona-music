import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/theme/semantic/app_typography.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/presentation/bloc/player_bloc.dart';

class QueueList extends StatelessWidget {
  const QueueList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (prev, curr) => _queueKey(prev) != _queueKey(curr),
      builder: (context, state) {
        if (state is! PlayerActive) {
          return const Center(child: Text('Aucune piste en cours'));
        }

        final queue = state.queue;
        final tracks = queue.playbackTracks;

        if (tracks.isEmpty) {
          return const Center(child: Text('Queue vide'));
        }

        return ReorderableListView.builder(
          padding: EdgeInsets.zero,
          itemCount: tracks.length,
          proxyDecorator: _proxyDecorator,
          onReorder: (oldIndex, newIndex) {
            // ReorderableListView passe newIndex après suppression de oldIndex
            if (newIndex > oldIndex) newIndex--;
            context.read<PlayerBloc>().add(QueueItemMoved(oldIndex: oldIndex, newIndex: newIndex));
          },
          itemBuilder: (context, index) {
            final track = tracks[index];
            final isCurrent = index == queue.currentIndex;

            return _QueueTile(
              key: ValueKey(track.id + index.toString()),
              track: track,
              index: index,
              isCurrent: isCurrent,
              onTap: () => context.read<PlayerBloc>().add(PlayTrackRequested(track)),
              onRemove: () => context.read<PlayerBloc>().add(TrackRemovedFromQueue(index: index)),
            );
          },
        );
      },
    );
  }

  // Décoratrice — ombre légère pendant le drag
  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) => Material(elevation: 0, color: Colors.transparent, child: child),
    );
  }

  Object? _queueKey(PlayerState s) => s is PlayerActive ? (s.queue.playbackTracks.length, s.queue.currentIndex) : null;
}

// ── Tile ───────────────────────────────────────────────────────────────────────

class _QueueTile extends StatelessWidget {
  final Track track;
  final int index;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _QueueTile({
    required this.track,
    required this.index,
    required this.isCurrent,
    required this.onTap,
    required this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppSpacing.trackRowHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            // Artwork
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: colors.bgSecondary),
              child: track.artworkPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(Uri.parse(track.artworkPath!).toFilePath() as dynamic, fit: BoxFit.cover),
                    )
                  : Icon(CupertinoIcons.music_note, size: 16, color: colors.labelTertiary),
            ),
            const SizedBox(width: AppSpacing.md),

            // Info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: isCurrent ? colors.accent : colors.labelPrimary,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artist,
                    style: AppTypography.textTheme.labelMedium?.copyWith(color: colors.labelSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Indicateur "en cours"
            if (isCurrent) Icon(CupertinoIcons.volume_up, color: colors.accent, size: 16),

            const SizedBox(width: AppSpacing.sm),

            // Bouton supprimer (swipe ou bouton)
            GestureDetector(
              onTap: onRemove,
              child: Icon(CupertinoIcons.minus_circle, color: colors.labelTertiary, size: 20),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Handle de réordonnancement
            ReorderableDragStartListener(
              index: index,
              child: Icon(CupertinoIcons.line_horizontal_3, color: colors.labelQuaternary, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
