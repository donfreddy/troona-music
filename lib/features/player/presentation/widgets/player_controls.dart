import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';

import 'package:troona/features/player/presentation/bloc/player_bloc.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (p, c) => _controlsKey(p) != _controlsKey(c),
      builder: (context, state) {
        if (state is! PlayerActive) return const SizedBox.shrink();

        return Column(
          children: [
            // ── Progress bar ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: SliderComponentShape.noOverlay,
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: state.progressRatio,
                      onChanged: (v) => context.read<PlayerBloc>().add(
                        SeekRequested(Duration(milliseconds: (v * state.duration.inMilliseconds).round())),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(state.position.toMMSS(), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        Text(state.duration.toMMSS(), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl2),

            // ── 5 boutons : shuffle·prev·play·next·repeat ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Shuffle
                  _ControlButton(
                    icon: CupertinoIcons.shuffle,
                    size: 22,
                    active: state.shuffleEnabled,
                    onPressed: () => context.read<PlayerBloc>().add(const ShuffleToggleRequested()),
                  ),

                  // Précédent
                  _ControlButton(
                    icon: CupertinoIcons.backward_fill,
                    size: 32,
                    onPressed: () => context.read<PlayerBloc>().add(const SkipPreviousRequested()),
                  ),

                  // Play / Pause — bouton principal
                  _PlayPauseButton(isPlaying: state.isPlaying, isBuffering: state.isBuffering),

                  // Suivant
                  _ControlButton(
                    icon: CupertinoIcons.forward_fill,
                    size: 32,
                    onPressed: () => context.read<PlayerBloc>().add(const SkipNextRequested()),
                  ),

                  // Repeat
                  _RepeatButton(mode: state.repeatMode),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Object? _controlsKey(PlayerState s) => switch (s) {
    PlayerActive(
      :final isPlaying,
      :final isBuffering,
      :final shuffleEnabled,
      :final repeatMode,
      :final progressRatio,
    ) =>
      (
        isPlaying, isBuffering, shuffleEnabled, repeatMode,
        // Arrondi à 0.5% pour éviter les rebuilds à chaque ms
        (progressRatio * 200).round(),
      ),
    _ => null,
  };
}

// ── Bouton play/pause avec spinner buffering ─────────────

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final bool isBuffering;
  const _PlayPauseButton({required this.isPlaying, required this.isBuffering});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<PlayerBloc>().add(isPlaying ? const PauseRequested() : const ResumeRequested()),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 72,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: isBuffering
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
              )
            : Icon(isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill, color: Colors.black, size: 30),
      ),
    );
  }
}

// ── Bouton générique ─────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool active;
  final VoidCallback onPressed;

  const _ControlButton({required this.icon, required this.size, required this.onPressed, this.active = false});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Icon(icon, size: size, color: active ? Colors.white : Colors.white70),
    );
  }
}

// ── Bouton repeat avec cycle off → one → all ─────────────

class _RepeatButton extends StatelessWidget {
  final RepeatMode mode;
  const _RepeatButton({required this.mode});

  @override
  Widget build(BuildContext context) {
    final next = switch (mode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => context.read<PlayerBloc>().add(RepeatModeChangeRequested(next)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(CupertinoIcons.repeat, size: 22, color: mode == RepeatMode.off ? Colors.white38 : Colors.white),
          if (mode == RepeatMode.one)
            const Positioned(
              bottom: 0,
              child: Text(
                '1',
                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}
