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
/// With nothing loaded they start instead, as songs of [origin]: the mini
/// player that comes up says it, no toast ([PlayerBloc.hasQueue]).
void queueSongs(
  BuildContext context,
  PlayerBloc player,
  List<Track> tracks, {
  required bool next,
  QueueOrigin? origin,
}) {
  if (tracks.isEmpty) return;
  final queues = player.hasQueue;
  player.add(TracksQueued(tracks, next: next, origin: origin));
  if (!queues || !context.mounted) return;
  final l10n = context.l10n;
  AppToast.show(context, next ? l10n.toastPlaysNext : l10n.toastAddedToQueue);
}
