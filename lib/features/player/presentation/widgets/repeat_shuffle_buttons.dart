import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';

class ShuffleButton extends StatelessWidget {
  const ShuffleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (prev, curr) => _shuffle(prev) != _shuffle(curr),
      builder: (context, state) {
        final enabled = _shuffle(state) ?? false;

        return _ControlButton(
          icon: AppIcons.shuffle,
          label: context.l10n.playerShuffle,
          active: enabled,
          onPressed: () =>
              context.read<PlayerBloc>().add(const ShuffleToggleRequested()),
        );
      },
    );
  }

  bool? _shuffle(PlayerState s) => s is PlayerActive ? s.shuffleEnabled : null;
}

class RepeatButton extends StatelessWidget {
  const RepeatButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (prev, curr) => _repeat(prev) != _repeat(curr),
      builder: (context, state) {
        final mode = _repeat(state) ?? RepeatMode.off;

        final l10n = context.l10n;
        void cycle() => context.read<PlayerBloc>().add(
          RepeatModeChangeRequested(_nextMode(mode)),
        );
        return Semantics(
          button: true,
          label: switch (mode) {
            RepeatMode.off => l10n.playerRepeatOff,
            RepeatMode.all => l10n.playerRepeatAll,
            RepeatMode.one => l10n.playerRepeatOne,
          },
          onTap: cycle,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: cycle,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                mode == RepeatMode.one ? AppIcons.repeatOne : AppIcons.repeat,
                color: mode == RepeatMode.off
                    ? Colors.white.withValues(alpha: .4)
                    : Colors.white,
                size: 22,
              ),
            ),
          ),
        );
      },
    );
  }

  RepeatMode? _repeat(PlayerState s) => s is PlayerActive ? s.repeatMode : null;

  RepeatMode _nextMode(RepeatMode current) => switch (current) {
    RepeatMode.off => RepeatMode.all,
    RepeatMode.all => RepeatMode.one,
    RepeatMode.one => RepeatMode.off,
  };
}

// ── Internal widget ───────────────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: active,
      label: label,
      onTap: onPressed,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: active ? Colors.white : Colors.white.withValues(alpha: .4),
            size: 22,
          ),
        ),
      ),
    );
  }
}
