import 'package:flutter/widgets.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/app_toast.dart';

/// Shows [notice] as a toast. [onUndo] brings back a replaced queue.
void showPlayerNotice(
  BuildContext context,
  PlayerNotice notice, {
  required VoidCallback onUndo,
}) {
  final l10n = context.l10n;
  switch (notice) {
    case TrackUnplayable(:final title?):
      AppToast.show(context, l10n.playerCantPlay(title));
    case TrackUnplayable():
      AppToast.show(context, l10n.playerCantPlayUnknown);
    case QueueReplaced():
      // Longer than a plain message: there is a choice to make.
      AppToast.show(
        context,
        l10n.playerQueueReplaced,
        actionLabel: l10n.actionUndo,
        onAction: onUndo,
        duration: const Duration(seconds: 5),
      );
  }
}
