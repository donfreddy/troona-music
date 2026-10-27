import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/playlist/presentation/widgets/playlist_mosaic.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

/// Square cover of a playlist, unclipped: the liked songs heart, the
/// playlist's own artwork, a mosaic of its tracks, or a placeholder.
///
/// Flat like every other cover: the caller clips the corners and adds no
/// border or glow.
class PlaylistCover extends StatelessWidget {
  final Playlist playlist;

  /// Displayed size, used to decode artwork and scale the icons.
  final double size;

  const PlaylistCover({super.key, required this.playlist, required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return switch (playlist) {
      Playlist(:final id) when id == Playlist.likesId => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.accent.withValues(alpha: .30),
              colors.accent.withValues(alpha: .08),
            ],
          ),
        ),
        child: Icon(LucideIcons.heart, color: colors.accent, size: size * .3),
      ),
      Playlist(:final artworkPath?) when artworkPath.isNotEmpty => ArtworkImage(
        artworkPath,
        width: size,
        height: size,
      ),
      Playlist(:final trackIds) when trackIds.isNotEmpty => PlaylistMosaic(
        trackIds: trackIds,
        size: size,
      ),
      _ => ColoredBox(
        color: Colors.white.withValues(alpha: .08),
        child: Icon(
          LucideIcons.listMusic,
          color: Colors.white30,
          size: size * .3,
        ),
      ),
    };
  }
}
