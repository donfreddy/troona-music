import 'package:flutter/widgets.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/queue_origin.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/app_toast.dart';

/// Queues [tracks] in one edit: right after the current song ([next]) or at
/// the end, then says so. Every Play next and Add to queue of a whole album
/// or artist goes through here.
///
/// The toast waits for the player: it shows once the songs are in, never
/// when the player refuses them, nor when they start instead (nothing
/// loaded: the mini player that comes up says it, as songs of [origin]).
void queueSongs(
  BuildContext context,
  PlayerBloc player,
  List<Track> tracks, {
  required bool next,
  QueueOrigin? origin,
}) {
  if (tracks.isEmpty) return;
  player.add(
    TracksQueued(
      tracks,
      next: next,
      origin: origin,
      onQueued: _toastOnce(context, next: next),
    ),
  );
}

/// [queueSongs] for one song: a swipe on its row, its menu.
void queueSong(
  BuildContext context,
  PlayerBloc player,
  Track track, {
  required bool next,
}) {
  final onQueued = _toastOnce(context, next: next);
  player.add(
    next
        ? TrackQueuedNext(track, onQueued: onQueued)
        : TrackAddedToQueue(track, onQueued: onQueued),
  );
}

/// The toast saying songs were queued, ready to show later: the overlay
/// and the words are read now, since the row or the sheet asking may be
/// gone by the time the player answers.
void Function() _toastOnce(BuildContext context, {required bool next}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  final l10n = context.l10n;
  final message = next ? l10n.toastPlaysNext : l10n.toastAddedToQueue;
  return () {
    if (overlay != null) AppToast.showOn(overlay, message);
  };
}
