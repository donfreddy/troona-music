import 'dart:io';

import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';

class TrendingRow extends StatelessWidget {
  final Track track;
  final int rank;
  final VoidCallback onTap;

  const TrendingRow({super.key, required this.track, required this.rank, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Vérifie si ce track est en cours de lecture
    final isActive = context.select<PlayerBloc, bool>(
      (b) => b.state is PlayerActive && (b.state as PlayerActive).currentTrack.id == track.id,
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Row(
          children: [
            // Artwork ou visualiseur si actif
            SizedBox.square(
              dimension: 50,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: track.artworkPath != null
                        ? Image.file(File(track.artworkPath!), width: 50, height: 50, fit: BoxFit.cover)
                        : Container(
                            color: Colors.white.withValues(alpha: .08),
                            child: const Icon(EvaIcons.musicOutline, color: Colors.white30),
                          ),
                  ),
                  // Overlay lecture en cours
                  if (isActive)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(EvaIcons.music, color: Colors.white, size: 20),
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
                      color: isActive ? Colors.white : Colors.white,
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(track.artist, style: TextStyle(color: Colors.white.withValues(alpha: .5), fontSize: 12)),
                ],
              ),
            ),

            Text(
              Duration(milliseconds: track.durationMs).toMMSS(),
              style: TextStyle(color: Colors.white.withValues(alpha: .4), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
