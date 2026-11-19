import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/bloc/selection/track_selection_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/utils/play_shuffled.dart';
import 'package:troona/features/player/presentation/utils/queue_songs.dart';
import 'package:troona/features/playlist/presentation/widgets/add_to_playlist_sheet.dart';
import 'package:troona/shared/widgets/app_icon_button.dart';

/// The floating bar's row while songs are picked: play them, shuffle them,
/// queue them next or last, add them to a playlist. They go in the list's
/// order, and each action ends the selection (Add to playlist once songs
/// were added: a sheet closed empty keeps it).
///
/// Icons only, as the tabs they stand in for: the label is the tooltip and
/// what a screen reader reads. No tick: playback ticks in the player, a
/// toast confirms the queue.
class SelectionActions extends StatelessWidget {
  const SelectionActions({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = context.colors.labelPrimary;

    Widget action(
      IconData icon,
      String label,
      void Function(List<Track> tracks) run,
    ) => Expanded(
      child: Center(
        child: AppIconButton(
          icon: icon,
          tooltip: label,
          color: color,
          onPressed: () {
            final tracks = context.read<TrackSelectionCubit>().state.tracks;
            if (tracks.isNotEmpty) run(tracks);
          },
        ),
      ),
    );

    void done() => context.read<TrackSelectionCubit>().end();
    PlayerBloc player() => context.read<PlayerBloc>();

    return Row(
      children: [
        action(AppIcons.play, l10n.actionPlay, (tracks) {
          player().add(
            PlayTrackRequested(
              tracks[0],
              contextQueue: tracks,
              contextIndex: 0,
            ),
          );
          done();
        }),
        action(AppIcons.shuffle, l10n.actionShuffle, (tracks) {
          playShuffled(player(), tracks);
          done();
        }),
        action(AppIcons.playNext, l10n.trackPlayNext, (tracks) {
          queueSongs(context, player(), tracks, next: true);
          done();
        }),
        action(AppIcons.addToQueue, l10n.trackAddToQueue, (tracks) {
          queueSongs(context, player(), tracks, next: false);
          done();
        }),
        action(AppIcons.addToPlaylist, l10n.playlistAddTo, (tracks) async {
          final cubit = context.read<TrackSelectionCubit>();
          final owner = cubit.state.owner;
          final added = await showAddTracksToPlaylistSheet(context, tracks);
          // Only the selection the sheet was opened for.
          if (added) cubit.end(owner);
        }),
      ],
    );
  }
}
