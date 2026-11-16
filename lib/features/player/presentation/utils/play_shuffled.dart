import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/domain/entities/queue_origin.dart';

/// Plays [tracks] from a random track with shuffle mode on. Every "Shuffle"
/// button goes through here.
void playShuffled(PlayerBloc bloc, List<Track> tracks, {QueueOrigin? origin}) {
  final event = shuffledPlayEvent(tracks, origin: origin);
  if (event != null) bloc.add(event);
}

/// One event, not play then toggle: the bloc is loading right after the
/// play request and ignores a toggle until the track is active. The queue
/// keeps the source order, so turning shuffle off later restores it.
@visibleForTesting
PlayTrackRequested? shuffledPlayEvent(
  List<Track> tracks, {
  Random? random,
  QueueOrigin? origin,
}) {
  if (tracks.isEmpty) return null;
  final start = (random ?? Random()).nextInt(tracks.length);
  return PlayTrackRequested(
    tracks[start],
    contextQueue: tracks,
    contextIndex: start,
    shuffle: true,
    origin: origin,
  );
}
