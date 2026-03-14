import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/widgets/repeat_shuffle_buttons.dart';

// Les 5 boutons : Shuffle · Prev · Play/Pause · Next · Repeat
// buildWhen granulaire : chaque bouton ne rebuild que si sa donnée change.

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

        return GestureDetector(
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
                        ? CupertinoIcons.pause_fill
                        : CupertinoIcons.play_fill,
                    color: Colors.black,
                    size: 30,
                  ),
          ),
        );
      },
    );
  }

  bool _isPlaying(PlayerState s) => s is PlayerActive && s.isPlaying;
  bool _isBuffering(PlayerState s) => s is PlayerActive && s.isBuffering;
}

// ── Skip précédent ────────────────────────────────────────────────────────────

class _SkipPreviousButton extends StatelessWidget {
  const _SkipPreviousButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (prev, curr) => _hasPrevious(prev) != _hasPrevious(curr),
      builder: (context, state) {
        final enabled = _hasPrevious(state);
        return GestureDetector(
          onTap: enabled
              ? () => context.read<PlayerBloc>().add(
                  const SkipPreviousRequested(),
                )
              : null,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(
              CupertinoIcons.backward_fill,
              color: enabled
                  ? Colors.white
                  : Colors.white.withValues(alpha: .3),
              size: 32,
            ),
          ),
        );
      },
    );
  }

  bool _hasPrevious(PlayerState s) =>
      s is PlayerActive && (s.hasPrevious || s.position.inSeconds > 3);
}

// ── Skip suivant ──────────────────────────────────────────────────────────────

class _SkipNextButton extends StatelessWidget {
  const _SkipNextButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (prev, curr) => _hasNext(prev) != _hasNext(curr),
      builder: (context, state) {
        final enabled = _hasNext(state);
        return GestureDetector(
          onTap: enabled
              ? () => context.read<PlayerBloc>().add(const SkipNextRequested())
              : null,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(
              CupertinoIcons.forward_fill,
              color: enabled
                  ? Colors.white
                  : Colors.white.withValues(alpha: .3),
              size: 32,
            ),
          ),
        );
      },
    );
  }

  bool _hasNext(PlayerState s) => s is PlayerActive && s.hasNext;
}
