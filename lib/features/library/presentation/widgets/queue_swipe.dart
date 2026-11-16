import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/app_toast.dart';
import 'package:troona/shared/widgets/swipe_actions.dart';

/// A song row that queues its song with a swipe: right plays it next, left
/// adds it to the end of the queue. The same actions, and toasts, as the
/// row's menu; screen readers get them as actions of the row.
///
/// The icon of the action waits at the edge the row leaves, and fills with
/// the accent once the swipe will count.
class QueueSwipe extends StatelessWidget {
  final Track track;
  final Widget child;

  const QueueSwipe({super.key, required this.track, required this.child});

  void _playNext(BuildContext context) {
    context.read<PlayerBloc>().add(TrackQueuedNext(track));
    AppToast.show(context, context.l10n.toastPlaysNext);
  }

  void _addToQueue(BuildContext context) {
    context.read<PlayerBloc>().add(TrackAddedToQueue(track));
    AppToast.show(context, context.l10n.toastAddedToQueue);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: l10n.trackPlayNext): () =>
            _playNext(context),
        CustomSemanticsAction(label: l10n.trackAddToQueue): () =>
            _addToQueue(context),
      },
      child: SwipeActions(
        onSwipeRight: () => _playNext(context),
        onSwipeLeft: () => _addToQueue(context),
        background: (context, direction, progress, armed) =>
            _Background(direction: direction, progress: progress, armed: armed),
        child: child,
      ),
    );
  }
}

class _Background extends StatelessWidget {
  final SwipeDirection direction;
  final double progress;
  final bool armed;

  const _Background({
    required this.direction,
    required this.progress,
    required this.armed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final right = direction == SwipeDirection.right;
    return Align(
      // The edge the row moves away from.
      alignment: right ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Opacity(
          opacity: progress,
          child: AnimatedScale(
            scale: armed ? 1 : .8,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: armed
                    ? colors.accent
                    : Colors.white.withValues(alpha: .12),
              ),
              child: Icon(
                right ? AppIcons.playNext : AppIcons.addToQueue,
                size: 18,
                color: armed ? colors.accentForeground : colors.labelPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
