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

/// Aucune piste n'a encore été jouée: état initial.
final class PlayerIdle extends PlayerState {
  const PlayerIdle();
}

/// Chargement en cours: on connaît déjà le track cible.
final class PlayerLoading extends PlayerState with EquatableMixin {
  final Track track;
  const PlayerLoading(this.track);

  @override
  List<Object?> get props => [track];
}

/// État principal : une piste est chargée, active ou en pause.
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

  // ── Helpers dérivés: jamais calculés dans les widgets ──────────────────

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

/// Erreur récupérable: l'utilisateur peut retenter.
final class PlayerError extends PlayerState {
  final String message;
  final Track? lastTrack;
  final Queue? lastQueue;

  const PlayerError({required this.message, this.lastTrack, this.lastQueue});
}
