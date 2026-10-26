import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';

/// Plays [tracks] from a random track with shuffle mode on. Every "Shuffle"
/// button goes through here.
void playShuffled(PlayerBloc bloc, List<Track> tracks) {
  final event = shuffledPlayEvent(tracks);
  if (event != null) bloc.add(event);
}

/// One event, not play then toggle: the bloc is loading right after the
/// play request and ignores a toggle until the track is active. The queue
/// keeps the source order, so turning shuffle off later restores it.
@visibleForTesting
PlayTrackRequested? shuffledPlayEvent(List<Track> tracks, {Random? random}) {
  if (tracks.isEmpty) return null;
  final start = (random ?? Random()).nextInt(tracks.length);
  return PlayTrackRequested(
    tracks[start],
    contextQueue: tracks,
    contextIndex: start,
    shuffle: true,
  );
}
