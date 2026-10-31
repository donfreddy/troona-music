part of 'player_bloc.dart';

/// One-shot playback event the shell turns into a localized toast.
sealed class PlayerNotice extends Equatable {
  const PlayerNotice();

  @override
  List<Object?> get props => [];
}

/// The engine could not decode the current song and skips past it.
final class TrackUnplayable extends PlayerNotice {
  final String? title;
  const TrackUnplayable(this.title);

  @override
  List<Object?> get props => [title];
}

/// A new album or playlist replaced a queue that still held songs queued
/// by hand. [QueueReplaceUndone] brings it back.
final class QueueReplaced extends PlayerNotice {
  const QueueReplaced();
}
