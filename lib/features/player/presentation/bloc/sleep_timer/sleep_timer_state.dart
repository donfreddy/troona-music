part of 'sleep_timer_cubit.dart';

sealed class SleepTimerState extends Equatable {
  const SleepTimerState();

  @override
  List<Object?> get props => [];
}

final class SleepTimerOff extends SleepTimerState {
  const SleepTimerOff();
}

/// Playback pauses at [endsAt].
final class SleepTimerRunning extends SleepTimerState {
  final DateTime endsAt;

  const SleepTimerRunning({required this.endsAt});

  @override
  List<Object?> get props => [endsAt];
}

/// Playback pauses when the current track ends.
final class SleepTimerEndOfTrack extends SleepTimerState {
  const SleepTimerEndOfTrack();
}
