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

/// Aucune piste n'a encore été jouée — état initial.
final class PlayerIdle extends PlayerState {
  const PlayerIdle();
}

/// Chargement en cours — on connaît déjà le track cible.
final class PlayerLoading extends PlayerState {
  final Track track;
  const PlayerLoading(this.track);
}

/// État principal : une piste est chargée, active ou en pause.
final class PlayerActive extends PlayerState {
  final Track currentTrack;
  final PlaybackStatusEvent status;
  final Duration position;
  final Duration buffered;
  final Duration duration;
  final Queue queue;
  final bool shuffleEnabled;
  final RepeatMode repeatMode;
  final double volume;
  final double speed;

  const PlayerActive({
    required this.currentTrack,
    required this.status,
    required this.position,
    required this.buffered,
    required this.duration,
    required this.queue,
    required this.shuffleEnabled,
    required this.repeatMode,
    this.volume = 1.0,
    this.speed = 1.0,
  });

  // ── Helpers dérivés — jamais calculés dans les widgets ──────────────────

  bool get isPlaying => status == PlaybackStatusEvent.playing;
  bool get isBuffering => status == PlaybackStatusEvent.buffering;
  bool get isPaused => status == PlaybackStatusEvent.paused;

  double get progressRatio {
    if (duration.inMilliseconds == 0) return 0.0;
    // Arrondi à 0.5% pour limiter les rebuilds du Slider
    final raw = position.inMilliseconds / duration.inMilliseconds;
    return (raw * 200).round() / 200.0.clamp(0.0, 1.0);
  }

  bool get hasNext => queue.hasNext;
  bool get hasPrevious => queue.hasPrevious;

  PlayerActive copyWith({
    Track? currentTrack,
    PlaybackStatusEvent? status,
    Duration? position,
    Duration? buffered,
    Duration? duration,
    Queue? queue,
    bool? shuffleEnabled,
    RepeatMode? repeatMode,
    double? volume,
    double? speed,
  }) => PlayerActive(
    currentTrack: currentTrack ?? this.currentTrack,
    status: status ?? this.status,
    position: position ?? this.position,
    buffered: buffered ?? this.buffered,
    duration: duration ?? this.duration,
    queue: queue ?? this.queue,
    shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
    repeatMode: repeatMode ?? this.repeatMode,
    volume: volume ?? this.volume,
    speed: speed ?? this.speed,
  );
}

/// Erreur récupérable — l'utilisateur peut retenter.
final class PlayerError extends PlayerState {
  final String message;
  final Track? lastTrack;
  final Queue? lastQueue;

  const PlayerError({required this.message, this.lastTrack, this.lastQueue});
}
