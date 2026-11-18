import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/player/presentation/bloc/palette/cover_palette.dart';
import 'package:troona/core/theme/primitives/color_primitives.dart';
import 'package:troona/features/library/domain/entities/track.dart';

class TrackPaletteState {
  final Color primary;
  final Color secondary;
  final Color backgroundColorA;
  final Color backgroundColorB;
  final String? trackId;

  const TrackPaletteState({
    required this.primary,
    required this.secondary,
    required this.backgroundColorA,
    required this.backgroundColorB,
    this.trackId,
  });

  /// The same colours, as [trackId]'s.
  TrackPaletteState forTrack(String trackId) => TrackPaletteState(
    primary: primary,
    secondary: secondary,
    backgroundColorA: backgroundColorA,
    backgroundColorB: backgroundColorB,
    trackId: trackId,
  );

  factory TrackPaletteState.initial() => const TrackPaletteState(
    primary: Color(0xFF7B4D91),
    secondary: Color(0xFF4A244F),
    backgroundColorA: ColorPrimitives.ambientTop,
    backgroundColorB: ColorPrimitives.ambientEdge,
  );
}

class TrackPaletteCubit extends Cubit<TrackPaletteState> {
  TrackPaletteCubit() : super(TrackPaletteState.initial());

  int _requestId = 0;

  Future<void> updateTrack(Track? track) async {
    final path = track?.artworkPath;
    if (track == null || path == null || path.isEmpty) {
      _requestId++;
      emit(TrackPaletteState.initial());
      return;
    }
    if (track.id == state.trackId) return;

    final requestId = ++_requestId;
    final colours = await CoverPalette.of(path);
    if (requestId != _requestId) return;
    emit((colours ?? TrackPaletteState.initial()).forTrack(track.id));
  }
}
