import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';

class ShuffleButton extends StatelessWidget {
  const ShuffleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (prev, curr) => _shuffle(prev) != _shuffle(curr),
      builder: (context, state) {
        final enabled = _shuffle(state) ?? false;

        return _ControlButton(
          icon: EvaIcons.shuffle2,
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

        return GestureDetector(
          onTap: () => context.read<PlayerBloc>().add(
            RepeatModeChangeRequested(_nextMode(mode)),
          ),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  mode == RepeatMode.one ? Icons.repeat_on_sharp : Icons.repeat,
                  color: mode == RepeatMode.off
                      ? Colors.white.withValues(alpha: .4)
                      : Colors.white,
                  size: 22,
                ),
                // Indicateur "1" sous l'icône pour RepeatOne
                if (mode == RepeatMode.one)
                  Positioned(
                    bottom: 6,
                    child: Container(
                      width: 16,
                      height: 10,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        '1',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
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

// ── Widget interne ────────────────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.active,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
    );
  }
}
