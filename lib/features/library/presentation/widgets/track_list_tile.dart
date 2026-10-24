import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/playlist/presentation/widgets/add_to_playlist_sheet.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

class TrackListTile extends StatefulWidget {
  final Track track;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const TrackListTile({
    super.key,
    required this.track,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<TrackListTile> createState() => _TrackListTileState();
}

class _TrackListTileState extends State<TrackListTile> {
  void _showContextMenu(BuildContext context) {
    final isLiked =
        context.read<LikesCubit>().state.isTrackLiked(widget.track.id);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(widget.track.title),
        message: Text(widget.track.artist),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<LikesCubit>().toggle(widget.track);
            },
            child: Text(
              isLiked ? 'Retirer des Titres likés' : 'Ajouter aux Titres likés',
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              showAddToPlaylistSheet(context, widget.track);
            },
            child: const Text('Ajouter à une playlist…'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Annuler'),
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
          (b.state as PlayerActive).currentTrack.id == widget.track.id,
    );
    final isLiked = context.select<LikesCubit, bool>(
      (c) => c.state.isTrackLiked(widget.track.id),
    );

    return InkWell(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress ?? () => _showContextMenu(context),
      highlightColor: colors.glassHighlight,
      splashColor: colors.glassHighlight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Artwork
            SizedBox.square(
              dimension: 50,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.track.artworkPath != null
                        ? ArtworkImage(
                            widget.track.artworkPath!,
                            width: 50,
                            height: 50,
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
                          color: Colors.black.withValues(alpha: .4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.music2,
                          color: colors.labelPrimary,
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
                    widget.track.title,
                    style: TextStyle(
                      color: isActive ? colors.accent : Colors.white,
                      fontSize: 15,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.track.artist,
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

            // Like quick button
            IconButton(
              icon: Icon(
                isLiked ? EvaIcons.heart : EvaIcons.heartOutline,
                size: 20,
                color: isLiked ? Colors.redAccent : Colors.white24,
              ),
              onPressed: () => context.read<LikesCubit>().toggle(widget.track),
            ),

            // More options button
            IconButton(
              icon: const Icon(
                LucideIcons.ellipsis,
                size: 18,
                color: Colors.white30,
              ),
              onPressed: () => _showContextMenu(context),
            ),
          ],
        ),
      ),
    );
  }
}
