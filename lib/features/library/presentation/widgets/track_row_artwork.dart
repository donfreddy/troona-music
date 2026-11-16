import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/shared/widgets/mini_equalizer.dart';

/// A song's cover in a list row. The current song's is dimmed under the
/// animated equalizer, which stands still while paused: the one look of the
/// current song in every list (Library, artists, search, playlists, Home).
/// Album rows, numbered, show the same equalizer in place of the number.
class TrackRowArtwork extends StatelessWidget {
  final Track track;
  final double size;

  const TrackRowArtwork({super.key, required this.track, this.size = 48});

  static const double radius = 10;

  /// Whether [trackId] is the current song, and whether it plays. Only these
  /// two flags: a watch on the whole state rebuilt every visible row on
  /// each player emission (volume drag included).
  static (bool, bool) statusOf(BuildContext context, String trackId) =>
      context.select<PlayerBloc, (bool, bool)>((bloc) {
        final state = bloc.state;
        final active =
            state is PlayerActive && state.currentTrack.id == trackId;
        return (active, active && state.isPlaying);
      });

  @override
  Widget build(BuildContext context) {
    final (active, playing) = statusOf(context, track.id);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: ArtworkImage(track.artworkPath, width: size, height: size),
          ),
          if (active)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: Center(
                  child: MiniEqualizer(
                    isPlaying: playing,
                    color: context.colors.accent,
                    size: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
