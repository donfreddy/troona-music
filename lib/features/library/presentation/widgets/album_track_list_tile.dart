import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';

class AlbumTrackListTile extends StatefulWidget {
  final Track track;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const AlbumTrackListTile({super.key, required this.track, required this.onTap, this.onLongPress});

  @override
  State<AlbumTrackListTile> createState() => _AlbumTrackListTileState();
}

class _AlbumTrackListTileState extends State<AlbumTrackListTile> {
  @override
  Widget build(BuildContext context) {
    final isActive = context.select<PlayerBloc, bool>(
      (b) => b.state is PlayerActive && (b.state as PlayerActive).currentTrack.id == widget.track.id,
    );

    return InkWell(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      highlightColor: context.colors.glassHighlight,
      splashColor: context.colors.glassHighlight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Row(
          children: [
            // Artwork
            SizedBox.square(
              dimension: 40,
              child: Stack(
                children: [
                  if (!isActive) Center(child: Text('${widget.track.trackNumber}')),

                  if (isActive)
                    Positioned.fill(child: Icon(LucideIcons.music2, color: context.colors.labelPrimary, size: 20)),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Info track
            Expanded(
              child: Text(
                widget.track.title,
                style: TextStyle(
                  color: context.colors.labelPrimary,
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            Text(
              widget.track.durationMs.ms.toMMSS(),
              style: TextStyle(color: context.colors.labelSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
