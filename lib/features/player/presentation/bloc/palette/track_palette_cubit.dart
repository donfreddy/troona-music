import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/player/presentation/bloc/palette/cover_palette.dart';
import 'package:troona/features/library/domain/entities/track.dart';

/// The glow colours of a cover: the background behind the tabs, Now
/// Playing and the playlist pages. Null with no cover: the app's ambient
/// glow, which follows the accent (`AmbientGlow.colorsOf`).
class TrackPaletteState {
  final Color? backgroundColorA;
  final Color? backgroundColorB;
  final String? trackId;

  const TrackPaletteState({
    required this.backgroundColorA,
    required this.backgroundColorB,
    this.trackId,
  });

  /// The same colours, as [trackId]'s.
  TrackPaletteState forTrack(String trackId) => TrackPaletteState(
    backgroundColorA: backgroundColorA,
    backgroundColorB: backgroundColorB,
    trackId: trackId,
  );

  factory TrackPaletteState.initial() =>
      const TrackPaletteState(backgroundColorA: null, backgroundColorB: null);
}

class TrackPaletteCubit extends Cubit<TrackPaletteState> {
  TrackPaletteCubit() : super(TrackPaletteState.initial());

  /// Bumped by every change of song: a read for a song no longer playing
  /// is dropped when it ends.
  int _requestId = 0;

  /// The song whose cover is being read.
  String? _pending;

  /// Called on every player state: most of them repeat the same song.
  Future<void> updateTrack(Track? track) async {
    final path = track?.artworkPath;
    if (track == null || path == null || path.isEmpty) {
      _requestId++;
      _pending = null;
      emit(TrackPaletteState.initial());
      return;
    }
    if (track.id == _pending) return;
    // Back to the song shown (A, B, A before B's cover is read): B's read
    // must not land.
    if (track.id == state.trackId) {
      _requestId++;
      _pending = null;
      return;
    }

    final requestId = ++_requestId;
    _pending = track.id;
    final colours = await CoverPalette.of(path);
    if (requestId != _requestId) return;
    _pending = null;
    emit((colours ?? TrackPaletteState.initial()).forTrack(track.id));
  }
}
