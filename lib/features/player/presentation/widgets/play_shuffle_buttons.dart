import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/utils/play_shuffled.dart';
import 'package:troona/shared/widgets/app_button.dart';

/// Play and Shuffle side by side, for the album, artist and playlist pages.
/// Both are disabled while [tracks] is empty.
///
/// They sit in the pages' fixed-height action bar (48 dp for the buttons):
/// the font size is capped at [AppLayout.maxTextScale].
class PlayShuffleButtons extends StatelessWidget {
  final List<Track> tracks;

  const PlayShuffleButtons({super.key, required this.tracks});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final empty = tracks.isEmpty;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: AppLayout.maxTextScale,
      child: Row(
        children: [
          Expanded(
            child: AppButton.primary(
              l10n.actionPlay,
              icon: AppIcons.play,
              expanded: true,
              onPressed: empty
                  ? null
                  : () {
                      AppHaptics.mediumImpact();
                      context.read<PlayerBloc>().add(
                        PlayTrackRequested(
                          tracks[0],
                          contextQueue: tracks,
                          contextIndex: 0,
                        ),
                      );
                    },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppButton.secondary(
              l10n.actionShuffle,
              icon: AppIcons.shuffle,
              expanded: true,
              onPressed: empty
                  ? null
                  : () {
                      AppHaptics.mediumImpact();
                      playShuffled(context.read<PlayerBloc>(), tracks);
                    },
            ),
          ),
        ],
      ),
    );
  }
}
