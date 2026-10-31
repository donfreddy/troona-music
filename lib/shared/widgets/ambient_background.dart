import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/shared/widgets/dynamic_background.dart';

/// The app's background: an opaque glow in the colours of the current
/// cover, behind [child].
///
/// The shell paints it behind the tab pages, which are transparent. A page
/// pushed over a tab paints its own, or the page below shows through it
/// while it slides in, then vanishes at once when the slide ends.
class AmbientBackground extends StatelessWidget {
  final Widget child;

  const AmbientBackground({super.key, this.child = const SizedBox.expand()});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<TrackPaletteCubit, TrackPaletteState>(
        builder: (_, palette) => DynamicBackground(
          colorA: palette.backgroundColorA,
          colorB: palette.backgroundColorB,
          tone: DynamicBackgroundTone.ambient,
          child: child,
        ),
      );
}
