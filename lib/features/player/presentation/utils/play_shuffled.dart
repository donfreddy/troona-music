import 'package:flutter/foundation.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';

/// Plays [tracks] in a random order, starting on a random track, with
/// shuffle mode on. Every "Shuffle" button goes through here.
void playShuffled(PlayerBloc bloc, List<Track> tracks) =>
    shuffledPlayEvents(bloc.state, tracks).forEach(bloc.add);

@visibleForTesting
List<PlayerEvent> shuffledPlayEvents(PlayerState state, List<Track> tracks) {
  if (tracks.isEmpty) return const [];
  final alreadyShuffled = switch (state) {
    PlayerActive(:final shuffleEnabled) => shuffleEnabled,
    _ => false,
  };
  final shuffled = List<Track>.of(tracks)..shuffle();
  return [
    PlayTrackRequested(shuffled.first, contextQueue: shuffled, contextIndex: 0),
    // A toggle: sending it while shuffle is on would turn it off.
    if (!alreadyShuffled) const ShuffleToggleRequested(),
  ];
}
