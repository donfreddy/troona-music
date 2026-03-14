import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';

class VolumeSlider extends StatelessWidget {
  const VolumeSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      // Ne rebuild que si le volume change
      buildWhen: (prev, curr) => _volume(prev) != _volume(curr),
      builder: (context, state) {
        final volume = _volume(state) ?? 1.0;

        return Row(
          children: [
            // Icône volume ba
            Icon(
              CupertinoIcons.volume_down,
              color: Colors.white.withValues(alpha: .6),
              size: 18,
            ),
            const SizedBox(width: 8),

            // Slider
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 5,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white.withValues(alpha: .3),
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withValues(alpha: .15),
                  showValueIndicator: ShowValueIndicator.never,
                ),
                child: Slider(
                  value: volume,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (v) =>
                      context.read<PlayerBloc>().add(VolumeChangeRequested(v)),
                ),
              ),
            ),

            const SizedBox(width: 8),
            // Icône volume haut
            Icon(
              CupertinoIcons.volume_up,
              color: Colors.white.withValues(alpha: .6),
              size: 18,
            ),
          ],
        );
      },
    );
  }

  double? _volume(PlayerState s) => s is PlayerActive ? s.volume : null;
}
