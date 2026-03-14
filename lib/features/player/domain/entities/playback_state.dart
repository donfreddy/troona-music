import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

enum PlaybackStatus { playing, paused, buffering, stopped }

/// Snapshot de l'état de lecture — exposé par l'AudioServicePort.
/// Distinct du PlayerState du Bloc : c'est la couche Domain pure.
@immutable
class PlaybackState extends Equatable {
  final PlaybackStatus status;
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
  final double speed;
  final double volume;

  const PlaybackState({
    required this.status,
    required this.position,
    required this.bufferedPosition,
    required this.duration,
    this.speed = 1.0,
    this.volume = 1.0,
  });

  static const empty = PlaybackState(
    status: PlaybackStatus.stopped,
    position: Duration.zero,
    bufferedPosition: Duration.zero,
    duration: Duration.zero,
  );

  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isBuffering => status == PlaybackStatus.buffering;
  bool get isPaused => status == PlaybackStatus.paused;

  double get progressRatio {
    if (duration.inMilliseconds == 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  PlaybackState copyWith({
    PlaybackStatus? status,
    Duration? position,
    Duration? bufferedPosition,
    Duration? duration,
    double? speed,
    double? volume,
  }) => PlaybackState(
    status: status ?? this.status,
    position: position ?? this.position,
    bufferedPosition: bufferedPosition ?? this.bufferedPosition,
    duration: duration ?? this.duration,
    speed: speed ?? this.speed,
    volume: volume ?? this.volume,
  );

  @override
  List<Object?> get props => [
    status,
    position,
    bufferedPosition,
    duration,
    speed,
    volume,
  ];
}
