import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';

/// Miniature 3-bar animated audio equalizer waveform.
///
/// Used in track rows to indicate the currently active song in Spotify & Apple Music style.
class MiniEqualizer extends StatelessWidget {
  final Color? color;
  final double size;
  final bool isPlaying;

  const MiniEqualizer({
    super.key,
    this.color,
    this.size = 14,
    this.isPlaying = true,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = color ?? context.colors.accent;
    final heights = [0.4, 1.0, 0.65];
    final durations = [600, 450, 750];

    return SizedBox(
      width: size,
      height: size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (index) {
          final bar = Container(
            width: size / 4.2,
            height: size * heights[index],
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(1.5),
            ),
          );

          if (!isPlaying) return bar;

          return bar
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleY(
                begin: 0.25,
                end: 1.0,
                duration: durations[index].ms,
                curve: Curves.easeInOut,
                alignment: Alignment.bottomCenter,
              );
        }),
      ),
    );
  }
}
