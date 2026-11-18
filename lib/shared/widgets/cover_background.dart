import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/player/presentation/bloc/palette/cover_palette.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/shared/widgets/dynamic_background.dart';

/// The background of an album or artist page: the glow in the colours of
/// its own cover, so each page has the colour of its place, not of the
/// song playing.
///
/// It opens in the colours of the song playing, the ones of the page it
/// slides over, then turns to its cover's once they are read (at once when
/// they already were, as for the album playing: nothing changes then).
/// [path] null means the cover is not known yet (the page is loading): the
/// colours of the song playing stay. An empty [path], or a cover that
/// cannot be read, gives the app's neutral glow.
class CoverBackground extends StatefulWidget {
  final String? path;
  final Widget child;

  const CoverBackground({super.key, required this.path, required this.child});

  @override
  State<CoverBackground> createState() => _CoverBackgroundState();
}

class _CoverBackgroundState extends State<CoverBackground> {
  /// The cover's colours, once read.
  TrackPaletteState? _colours;

  @override
  void initState() {
    super.initState();
    _read();
  }

  @override
  void didUpdateWidget(CoverBackground old) {
    super.didUpdateWidget(old);
    if (widget.path != old.path) _read();
  }

  void _read() {
    final path = widget.path;
    if (path == null) return;
    if (path.isEmpty) {
      _colours = TrackPaletteState.initial();
      return;
    }
    // Known colours at once, then checked against the file: an artist's
    // photo may have been downloaded again since.
    _colours = CoverPalette.cached(path) ?? _colours;
    CoverPalette.of(path).then((colours) {
      if (!mounted || widget.path != path) return;
      final read = colours ?? TrackPaletteState.initial();
      if (read != _colours) setState(() => _colours = read);
    });
  }

  // The same tree whichever colours it paints, so turning to the cover's
  // cross-fades the one glow instead of building another.
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<TrackPaletteCubit, TrackPaletteState>(
        buildWhen: (_, _) => _colours == null,
        builder: (_, playing) {
          final colours = _colours ?? playing;
          return DynamicBackground(
            colorA: colours.backgroundColorA,
            colorB: colours.backgroundColorB,
            tone: DynamicBackgroundTone.immersive,
            child: widget.child,
          );
        },
      );
}
