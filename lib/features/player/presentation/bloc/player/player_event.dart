part of 'player_bloc.dart';

sealed class PlayerEvent {
  const PlayerEvent();
}

// ── Commandes utilisateur ─────────────────────────────────────────────────────

final class PlayTrackRequested extends PlayerEvent {
  final Track track;
  final List<Track>? contextQueue; // liste source complète (album, playlist…)
  final int? contextIndex;
  const PlayTrackRequested(this.track, {this.contextQueue, this.contextIndex});
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

// ── Queue management ──────────────────────────────────────────────────────────

final class QueueSetRequested extends PlayerEvent {
  final List<Track> tracks;
  final int startIndex;
  const QueueSetRequested(this.tracks, {this.startIndex = 0});
}

final class TrackAddedToQueue extends PlayerEvent {
  final Track track;
  const TrackAddedToQueue(this.track);
}

final class TrackRemovedFromQueue extends PlayerEvent {
  final int index;
  const TrackRemovedFromQueue({required this.index});
}

final class QueueItemMoved extends PlayerEvent {
  final int oldIndex;
  final int newIndex;
  const QueueItemMoved({required this.oldIndex, required this.newIndex});
}

// ── Streams entrants (internes — jamais émis par l'UI) ────────────────────────

final class _PositionUpdated extends PlayerEvent {
  final Duration position;
  const _PositionUpdated(this.position);
}

final class _BufferedUpdated extends PlayerEvent {
  final Duration buffered;
  const _BufferedUpdated(this.buffered);
}

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
