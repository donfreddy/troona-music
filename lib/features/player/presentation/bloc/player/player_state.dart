part of 'player_bloc.dart';

// abstract class PlayerState extends Equatable {
//   const PlayerState();

//   @override
//   List<Object> get props => [];
// }
// class PlayerInitial extends PlayerState {}

sealed class PlayerState {
  const PlayerState();
}

/// Initial state: nothing has been played yet.
final class PlayerIdle extends PlayerState {
  const PlayerIdle();
}

/// Loading; the target track is already known.
final class PlayerLoading extends PlayerState with EquatableMixin {
  final Track track;
  const PlayerLoading(this.track);

  @override
  List<Object?> get props => [track];
}

/// Main state: a track is loaded, playing or paused.
///
/// Position and buffering are not part of this state: they live in
/// [PlayerBloc.progress] so playback ticks never trigger a rebuild.
/// Value equality lets the bloc drop redundant emissions.
final class PlayerActive extends PlayerState with EquatableMixin {
  final Track currentTrack;
  final PlaybackStatus status;
  final Duration duration;
  final Queue queue;
  final bool shuffleEnabled;
  final RepeatMode repeatMode;
  final double volume;
  final double speed;

  const PlayerActive({
    required this.currentTrack,
    required this.status, // PlaybackStatus from domain: single source of truth
    required this.duration,
    required this.queue,
    required this.shuffleEnabled,
    required this.repeatMode,
    this.volume = 1.0,
    this.speed = 1.0,
  });

  // ── Derived helpers, never computed in widgets ──────────────────

  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isBuffering => status == PlaybackStatus.buffering;
  bool get isPaused => status == PlaybackStatus.paused;

  bool get hasNext => queue.hasNext;
  bool get hasPrevious => queue.hasPrevious;

  PlayerActive copyWith({
    Track? currentTrack,
    PlaybackStatus? status,
    Duration? duration,
    Queue? queue,
    bool? shuffleEnabled,
    RepeatMode? repeatMode,
    double? volume,
    double? speed,
  }) => PlayerActive(
    currentTrack: currentTrack ?? this.currentTrack,
    status: status ?? this.status,
    duration: duration ?? this.duration,
    queue: queue ?? this.queue,
    shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
    repeatMode: repeatMode ?? this.repeatMode,
    volume: volume ?? this.volume,
    speed: speed ?? this.speed,
  );

  @override
  List<Object?> get props => [
    currentTrack,
    status,
    duration,
    queue,
    shuffleEnabled,
    repeatMode,
    volume,
    speed,
  ];
}

/// Recoverable error: the user can try again.
final class PlayerError extends PlayerState {
  final String message;
  final Track? lastTrack;
  final Queue? lastQueue;

  const PlayerError({required this.message, this.lastTrack, this.lastQueue});
}
