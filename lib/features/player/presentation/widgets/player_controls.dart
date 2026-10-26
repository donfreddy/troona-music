import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/widgets/repeat_shuffle_buttons.dart';
import 'package:troona/core/extensions/context_ext.dart';

// Five buttons: shuffle, previous, play/pause, next, repeat.
// Granular buildWhen: each button rebuilds only when its own data changes.

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (prev, curr) =>
          _isPlaying(prev) != _isPlaying(curr) ||
          _isBuffering(prev) != _isBuffering(curr),
      builder: (context, state) {
        final isPlaying = _isPlaying(state);
        final isBuffering = _isBuffering(state);

        return Semantics(
          button: true,
          label: isPlaying ? context.l10n.playerPause : context.l10n.actionPlay,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => context.read<PlayerBloc>().add(
              isPlaying ? const PauseRequested() : const ResumeRequested(),
            ),
            child: Container(
              width: 72,
              height: 72,
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
                      isPlaying
                          ? EvaIcons.pauseCircleOutline
                          : EvaIcons.playCircleOutline,
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
        return Semantics(
          button: true,
          enabled: enabled,
          label: context.l10n.playerPrevious,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: enabled
                ? () => context.read<PlayerBloc>().add(
                    const SkipPreviousRequested(),
                  )
                : null,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(
                EvaIcons.skipBackOutline,
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
        return Semantics(
          button: true,
          enabled: enabled,
          label: context.l10n.playerNext,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: enabled
                ? () =>
                      context.read<PlayerBloc>().add(const SkipNextRequested())
                : null,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(
                EvaIcons.skipForwardOutline,
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
