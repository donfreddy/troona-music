import 'package:flutter/foundation.dart';
import 'package:troona/features/player/domain/entities/opened_audio.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';

/// What the shell does with a file opened from another app. Its song
/// plays alone, on Now Playing: the song the user touched, not its album.
/// A cold start's restore steps aside first ([skipRestore]): the file wins
/// over the last session, and over Now Playing pushed for it. A file the
/// library does not hold is only said to be so.
void playOpenedFile(
  OpenedAudio opened, {
  required PlayerBloc player,
  required bool nowPlayingOnTop,
  required VoidCallback skipRestore,
  required VoidCallback showNowPlaying,
  required VoidCallback sayNotInLibrary,
}) {
  switch (opened) {
    case OpenedLibraryTrack(:final track):
      skipRestore();
      player.add(PlayTrackRequested(track));
      if (!nowPlayingOnTop) showNowPlaying();
    case OpenedNotInLibrary():
      sayNotInLibrary();
  }
}
