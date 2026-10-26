import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/widgets/track_actions/show_track_actions.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';

class AlbumTrackListTile extends StatefulWidget {
  final Track track;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const AlbumTrackListTile({
    super.key,
    required this.track,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<AlbumTrackListTile> createState() => _AlbumTrackListTileState();
}

class _AlbumTrackListTileState extends State<AlbumTrackListTile> {
  bool _pressed = false;

  void _showContextMenu(BuildContext context) {
    showTrackActions(context, widget.track, origin: TrackActionOrigin.album);
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
      onHighlightChanged: (value) => setState(() => _pressed = value),
      onLongPress: widget.onLongPress ?? () => _showContextMenu(context),
      highlightColor: colors.glassHighlight,
      splashColor: colors.glassHighlight,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
          children: [
            // Track number or active icon
            SizedBox.square(
              dimension: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!isActive)
                    Text(
                      '${widget.track.trackNumber}',
                      style: TextStyle(
                        color: colors.labelSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (isActive)
                    Icon(
                      LucideIcons.music2,
                      color: colors.accent,
                      size: 20,
                    ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Track title
            Expanded(
              child: Text(
                widget.track.title,
                style: TextStyle(
                  color: isActive ? colors.accent : colors.labelPrimary,
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Quick like button
            IconButton(
              icon: Icon(
                isLiked ? EvaIcons.heart : EvaIcons.heartOutline,
                size: 18,
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
    ),
  );
}
}
