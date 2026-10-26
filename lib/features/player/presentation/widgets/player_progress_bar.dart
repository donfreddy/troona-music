import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/core/theme/semantic/app_typography.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';

class PlayerProgressBar extends StatelessWidget {
  const PlayerProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      // Ticks are handled by the ValueListenableBuilder below.
      buildWhen: (prev, curr) =>
          prev.runtimeType != curr.runtimeType ||
          (prev is PlayerActive &&
              curr is PlayerActive &&
              prev.isBuffering != curr.isBuffering),
      builder: (context, state) {
        if (state is! PlayerActive) return const SizedBox.shrink();

        return ValueListenableBuilder<PlaybackProgress>(
          valueListenable: context.read<PlayerBloc>().progress,
          builder: (context, progress, _) =>
              _buildBar(context, state, progress),
        );
      },
    );
  }

  Widget _buildBar(
    BuildContext context,
    PlayerActive state,
    PlaybackProgress progress,
  ) {
    //final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Slider ────────────────────────────────────────────────────
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withValues(alpha: .3),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: .15),
            // Pas de tick marks
            showValueIndicator: ShowValueIndicator.never,
          ),
          child: Slider(
            value: progress.ratio,
            min: 0.0,
            max: 1.0,
            onChanged: (value) {
              // Seeks on every drag update (kept as is: this widget is currently unused)
              context.read<PlayerBloc>().add(
                SeekRequested(
                  Duration(
                    milliseconds: (value * progress.duration.inMilliseconds)
                        .round(),
                  ),
                ),
              );
            },
          ),
        ),

        // ── Position and duration labels ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                progress.position.toMMSS(),
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: .7),
                ),
              ),
              // Buffering indicator
              if (state.isBuffering)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Colors.white.withValues(alpha: .7),
                  ),
                ),
              Text(
                progress.duration.toMMSS(),
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: .7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
