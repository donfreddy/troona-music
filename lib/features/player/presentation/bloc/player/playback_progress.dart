part of 'player_bloc.dart';

/// High-frequency playback clock, deliberately kept out of [PlayerState].
///
/// Position ticks arrive at up to 60 fps. Routing them through `emit` would
/// rebuild every [BlocBuilder] listening to the player. Instead, [PlayerBloc]
/// exposes this value through a [ValueListenable] so only the widgets that
/// draw time (mini player fill, time labels) repaint.
@immutable
final class PlaybackProgress {
  final Duration position;
  final Duration buffered;
  final Duration duration;

  const PlaybackProgress({
    required this.position,
    required this.buffered,
    required this.duration,
  });

  static const zero = PlaybackProgress(
    position: Duration.zero,
    buffered: Duration.zero,
    duration: Duration.zero,
  );

  /// Elapsed fraction in `[0, 1]`; 0 while the duration is unknown.
  double get ratio {
    if (duration <= Duration.zero) return 0.0;
    return (position.inMicroseconds / duration.inMicroseconds).clamp(0.0, 1.0);
  }

  /// Time left, never negative.
  Duration get remaining {
    final left = duration - position;
    return left.isNegative ? Duration.zero : left;
  }

  PlaybackProgress copyWith({
    Duration? position,
    Duration? buffered,
    Duration? duration,
  }) => PlaybackProgress(
    position: position ?? this.position,
    buffered: buffered ?? this.buffered,
    duration: duration ?? this.duration,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackProgress &&
          position == other.position &&
          buffered == other.buffered &&
          duration == other.duration;

  @override
  int get hashCode => Object.hash(position, buffered, duration);
}
