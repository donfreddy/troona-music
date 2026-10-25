import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:palette_generator_master/palette_generator_master.dart';
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

  factory TrackPaletteState.initial() => const TrackPaletteState(
    primary: Color(0xFF7B4D91),
    secondary: Color(0xFF4A244F),
    backgroundColorA: ColorPrimitives.ambientTop,
    backgroundColorB: ColorPrimitives.ambientEdge,
  );
}

class TrackPaletteCubit extends Cubit<TrackPaletteState> {
  TrackPaletteCubit() : super(TrackPaletteState.initial());

  final Map<String, TrackPaletteState> _cache = {};
  int _requestId = 0;

  Future<void> updateTrack(Track? track) async {
    if (track == null) {
      emit(TrackPaletteState.initial());
      return;
    }

    if (track.id == state.trackId) return;

    if (_cache.containsKey(track.id)) {
      emit(_cache[track.id]!);
      return;
    }

    if (track.artworkPath == null) {
      emit(TrackPaletteState.initial());
      return;
    }

    final requestId = ++_requestId;

    try {
      final palette = await PaletteGeneratorMaster.fromImageProvider(
        FileImage(File(track.artworkPath!)),
        size: const Size(64, 64),
      );

      if (requestId != _requestId) return;

      final primaryColor =
          palette.vibrantColor?.color ??
          palette.dominantColor?.color ??
          const Color(0xFF1A0533);

      final secondaryColor =
          palette.darkVibrantColor?.color ??
          palette.mutedColor?.color ??
          primaryColor;

      Color adaptAccent(Color c) {
        final hsl = HSLColor.fromColor(c);
        return hsl
            .withSaturation((hsl.saturation * 1.2).clamp(0.5, 0.9))
            .withLightness(0.6)
            .toColor();
      }

      Color adaptBg(Color c, {required bool isTop}) {
        final hsl = HSLColor.fromColor(c);
        return hsl
            .withSaturation((hsl.saturation * 1.1).clamp(0.4, 0.9))
            .withLightness(isTop ? 0.25 : 0.15)
            .toColor();
      }

      final newState = TrackPaletteState(
        primary: adaptAccent(primaryColor),
        secondary: adaptAccent(secondaryColor),
        backgroundColorA: adaptBg(primaryColor, isTop: true),
        backgroundColorB: adaptBg(secondaryColor, isTop: false),
        trackId: track.id,
      );

      _cache[track.id] = newState;
      emit(newState);
    } catch (_) {
      if (requestId == _requestId) emit(TrackPaletteState.initial());
    }
  }
}
