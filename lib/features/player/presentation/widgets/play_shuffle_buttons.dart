import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
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

/// Shuffle alone, as a round accent button: the artist page's one action.
/// The order of an artist's songs means nothing, so they play shuffled; a
/// song tapped in their list plays in order from there.
///
/// It sinks a little under a press. Disabled while [tracks] is empty.
class ShuffleRoundButton extends StatefulWidget {
  final List<Track> tracks;

  const ShuffleRoundButton({super.key, required this.tracks});

  static const double diameter = 56;

  @override
  State<ShuffleRoundButton> createState() => _ShuffleRoundButtonState();
}

class _ShuffleRoundButtonState extends State<ShuffleRoundButton> {
  var _pressed = false;

  void _press(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = widget.tracks.isNotEmpty;
    final label = context.l10n.actionShuffle;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      onTap: enabled ? _shuffle : null,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _press(true) : null,
          onTapUp: enabled ? (_) => _press(false) : null,
          onTapCancel: () => _press(false),
          onTap: enabled ? _shuffle : null,
          child: AnimatedScale(
            scale: _pressed ? .92 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Container(
              width: ShuffleRoundButton.diameter,
              height: ShuffleRoundButton.diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enabled
                    ? colors.accent
                    : colors.accent.withValues(alpha: .38),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                AppIcons.shuffle,
                size: 24,
                color: colors.accentForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _shuffle() {
    AppHaptics.mediumImpact();
    playShuffled(context.read<PlayerBloc>(), widget.tracks);
  }
}
