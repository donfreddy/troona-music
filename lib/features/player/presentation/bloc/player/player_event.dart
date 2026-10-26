part of 'player_bloc.dart';

sealed class PlayerEvent {
  const PlayerEvent();
}

// ── Commandes utilisateur ─────────────────────────────────────────────────────

final class PlayTrackRequested extends PlayerEvent {
  final Track track;
  final List<Track>? contextQueue; // full source list (album, playlist...)
  final int? contextIndex;

  /// With [contextQueue]: turn shuffle mode on in the same step. False keeps
  /// the current mode.
  final bool shuffle;
  const PlayTrackRequested(
    this.track, {
    this.contextQueue,
    this.contextIndex,
    this.shuffle = false,
  });
}

final class PauseRequested extends PlayerEvent {
  const PauseRequested();
}

final class ResumeRequested extends PlayerEvent {
  const ResumeRequested();
}

final class SeekRequested extends PlayerEvent {
  final Duration position;
  const SeekRequested(this.position);
}

final class SkipNextRequested extends PlayerEvent {
  const SkipNextRequested();
}

final class SkipPreviousRequested extends PlayerEvent {
  const SkipPreviousRequested();
}

final class ShuffleToggleRequested extends PlayerEvent {
  const ShuffleToggleRequested();
}

final class RepeatModeChangeRequested extends PlayerEvent {
  final RepeatMode mode;
  const RepeatModeChangeRequested(this.mode);
}

final class VolumeChangeRequested extends PlayerEvent {
  final double volume; // 0.0 – 1.0
  const VolumeChangeRequested(this.volume);
}

final class SpeedChangeRequested extends PlayerEvent {
  final double speed; // 0.5 – 2.0
  const SpeedChangeRequested(this.speed);
}

final class PlayerDismissed extends PlayerEvent {
  const PlayerDismissed();
}

final class RestorePlaybackSessionRequested extends PlayerEvent {
  const RestorePlaybackSessionRequested();
}

// ── Queue management ──────────────────────────────────────────────────────────

/// Plays the track at [index] of the current queue, keeping the queue
/// (order and shuffle) as it is. Used by carousel swipes.
final class QueueIndexRequested extends PlayerEvent {
  final int index;
  const QueueIndexRequested(this.index);
}

final class QueueSetRequested extends PlayerEvent {
  final List<Track> tracks;
  final int startIndex;
  const QueueSetRequested(this.tracks, {this.startIndex = 0});
}

/// Queue edits. Handled by a single sequential handler: each edit is
/// defined against the queue left by the previous one, whatever its type.
sealed class QueueEditEvent extends PlayerEvent {
  const QueueEditEvent();
}

final class TrackAddedToQueue extends QueueEditEvent {
  final Track track;

  /// Playback index to insert at (e.g. undoing a removal); null appends.
  final int? index;

  /// The removal this insert undoes: skipped if that removal did not
  /// happen (rejected by the player, or skipped as stale), which would
  /// otherwise queue the track twice.
  final TrackRemovedFromQueue? undoing;

  const TrackAddedToQueue(this.track, {this.index, this.undoing});
}

/// Edits address tracks by index, computed on the queue the UI shows. When
/// an earlier edit is rejected, later indexes point at other tracks: with
/// [trackId] set, an edit whose track is no longer at its index is skipped.
final class TrackRemovedFromQueue extends QueueEditEvent {
  final int index;

  /// Id of the track expected at [index].
  final String? trackId;

  const TrackRemovedFromQueue({required this.index, this.trackId});
}

final class QueueItemMoved extends QueueEditEvent {
  final int oldIndex;
  final int newIndex;

  /// Id of the track expected at [oldIndex].
  final String? trackId;

  const QueueItemMoved({
    required this.oldIndex,
    required this.newIndex,
    this.trackId,
  });
}

// ── Streams entrants (internal, never sent by the UI) ────────────────────────

final class _DurationUpdated extends PlayerEvent {
  final Duration duration;
  const _DurationUpdated(this.duration);
}

final class _StatusChanged extends PlayerEvent {
  final PlaybackStatus status;
  const _StatusChanged(this.status);
}

final class _TrackChanged extends PlayerEvent {
  final Track? track;
  const _TrackChanged(this.track);
}

final class _QueueChanged extends PlayerEvent {
  final Queue queue;
  const _QueueChanged(this.queue);
}

final class _VolumeUpdated extends PlayerEvent {
  final double volume;
  const _VolumeUpdated(this.volume);
}

final class _AudioErrorOccurred extends PlayerEvent {
  final String message;
  const _AudioErrorOccurred(this.message);
}

final class TrackQueuedNext extends QueueEditEvent {
  final Track track;
  const TrackQueuedNext(this.track);
}
