import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/widgets/repeat_shuffle_buttons.dart';
import 'package:troona/core/extensions/context_ext.dart';

// Five buttons: shuffle, previous, play/pause, next, repeat.
// Granular buildWhen: each button rebuilds only when its own data changes.

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  /// The play button, the tallest of the row.
  static const height = _PlayPauseButton.size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const ShuffleButton(),
          const _SkipPreviousButton(),
          const _PlayPauseButton(),
          const _SkipNextButton(),
          const RepeatButton(),
        ],
      ),
    );
  }
}

// ── Play / Pause ──────────────────────────────────────────────────────────────

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton();

  static const size = 72.0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (prev, curr) =>
          _isPlaying(prev) != _isPlaying(curr) ||
          _isBuffering(prev) != _isBuffering(curr),
      builder: (context, state) {
        final isPlaying = _isPlaying(state);
        final isBuffering = _isBuffering(state);

        void toggle() => context.read<PlayerBloc>().add(
          isPlaying ? const PauseRequested() : const ResumeRequested(),
        );
        // excludeSemantics drops the child's tap action: hand it back here.
        return Semantics(
          button: true,
          label: isPlaying ? context.l10n.playerPause : context.l10n.actionPlay,
          onTap: toggle,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: toggle,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: isBuffering
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black.withValues(alpha: .6),
                      ),
                    )
                  : Icon(
                      isPlaying ? AppIcons.pause : AppIcons.play,
                      color: Colors.black,
                      size: 30,
                    ),
            ),
          ),
        );
      },
    );
  }

  bool _isPlaying(PlayerState s) => s is PlayerActive && s.isPlaying;
  bool _isBuffering(PlayerState s) => s is PlayerActive && s.isBuffering;
}

// ── Skip previous ─────────────────────────────────────────────────────────────

class _SkipPreviousButton extends StatelessWidget {
  const _SkipPreviousButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (prev, curr) => _hasPrevious(prev) != _hasPrevious(curr),
      builder: (context, state) {
        final enabled = _hasPrevious(state);
        final VoidCallback? onTap = enabled
            ? () =>
                  context.read<PlayerBloc>().add(const SkipPreviousRequested())
            : null;
        return Semantics(
          button: true,
          enabled: enabled,
          label: context.l10n.playerPrevious,
          onTap: onTap,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onTap,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(
                AppIcons.skipPrevious,
                color: enabled
                    ? Colors.white
                    : Colors.white.withValues(alpha: .3),
                size: 32,
              ),
            ),
          ),
        );
      },
    );
  }

  // Always available while a track is loaded: on the first track (or past
  // 3 s) the bloc restarts the current track instead of skipping.
  bool _hasPrevious(PlayerState s) => s is PlayerActive;
}

// ── Skip next ─────────────────────────────────────────────────────────────────

class _SkipNextButton extends StatelessWidget {
  const _SkipNextButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (prev, curr) => _hasNext(prev) != _hasNext(curr),
      builder: (context, state) {
        final enabled = _hasNext(state);
        final VoidCallback? onTap = enabled
            ? () => context.read<PlayerBloc>().add(const SkipNextRequested())
            : null;
        return Semantics(
          button: true,
          enabled: enabled,
          label: context.l10n.playerNext,
          onTap: onTap,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onTap,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(
                AppIcons.skipNext,
                color: enabled
                    ? Colors.white
                    : Colors.white.withValues(alpha: .3),
                size: 32,
              ),
            ),
          ),
        );
      },
    );
  }

  bool _hasNext(PlayerState s) => s is PlayerActive && s.hasNext;
}
