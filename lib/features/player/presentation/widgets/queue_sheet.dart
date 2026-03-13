import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/theme/semantic/app_typography.dart';
import 'package:troona/features/player/presentation/bloc/player_bloc.dart';
import 'package:troona/features/player/presentation/widgets/queue_list.dart';
import 'package:troona/shared/widgets/glass_card.dart';

/// Ouvre la QueueSheet depuis le FullPlayerPage.
Future<void> showQueueSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .5),
    builder: (ctx) => BlocProvider.value(value: context.read<PlayerBloc>(), child: const QueueSheet()),
  );
}

class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context) {
    //final safeBottom = MediaQuery.of(context).padding.bottom;
    final colors = context.colors;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return GlassCard(
          config: GlassTheme.sheet(context),
          child: Column(
            children: [
              // ── Drag handle ───────────────────────────────────────────
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: colors.labelQuaternary, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'File d\'attente',
                      style: AppTypography.textTheme.headlineSmall?.copyWith(color: colors.labelPrimary),
                    ),
                    BlocBuilder<PlayerBloc, PlayerState>(
                      buildWhen: (prev, curr) => _queueLength(prev) != _queueLength(curr),
                      builder: (_, state) {
                        final count = _queueLength(state);
                        return Text(
                          count != null ? '$count titres' : '',
                          style: AppTypography.textTheme.labelLarge?.copyWith(color: colors.labelSecondary),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Divider ───────────────────────────────────────────────
              Divider(height: 0.5, color: colors.separator),

              // ── Liste réordonnables ───────────────────────────────────
              Expanded(child: QueueList()),

              // ── Clear queue button ────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
                  child: CupertinoButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // TODO : implémenter ClearQueueRequested si besoin
                    },
                    child: Text(
                      'Vider la queue',
                      style: AppTypography.textTheme.bodySmall?.copyWith(color: colors.accent),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int? _queueLength(PlayerState s) => s is PlayerActive ? s.queue.length : null;
}
