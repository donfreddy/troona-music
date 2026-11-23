import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/palette_ink_scope.dart';

/// A thin seek bar with the position and the length, for when the ring is
/// not on screen (Now Playing showing lyrics). A drag moves the thumb and
/// seeks once, where the finger lets go.
class PlayerProgressBar extends StatefulWidget {
  const PlayerProgressBar({super.key});

  /// Its height: the slider's touch target and the labels.
  static const height = 52.0;

  @override
  State<PlayerProgressBar> createState() => _PlayerProgressBarState();
}

class _PlayerProgressBarState extends State<PlayerProgressBar> {
  /// The thumb under a finger, as a share of the length; null otherwise.
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PlayerBloc>();
    // Small text over the glow: its tint, never a fixed grey.
    final ink = PaletteInkScope.of(context);
    return SizedBox(
      height: PlayerProgressBar.height,
      child: ValueListenableBuilder<PlaybackProgress>(
        valueListenable: bloc.progress,
        builder: (context, progress, _) {
          final ratio = _dragging ?? progress.ratio;
          final known = progress.duration > Duration.zero;
          final shown = _dragging == null
              ? progress.position
              : progress.duration * ratio;
          final label = TextStyle(
            fontSize: 12,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: ink.secondary,
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 32,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16,
                    ),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: ink.far,
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withValues(alpha: .15),
                    showValueIndicator: ShowValueIndicator.never,
                  ),
                  child: Slider(
                    value: ratio,
                    onChanged: known
                        ? (value) => setState(() => _dragging = value)
                        : null,
                    onChangeEnd: known
                        ? (value) {
                            setState(() => _dragging = null);
                            bloc.add(SeekRequested(progress.duration * value));
                          }
                        : null,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(shown.toMMSS(), style: label),
                    Text(progress.duration.toMMSS(), style: label),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
