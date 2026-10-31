import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/bloc/sleep_timer/sleep_timer_cubit.dart';
import 'package:troona/features/player/presentation/widgets/queue_sheet.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/components/glass_filter.dart';
import 'package:troona/shared/widgets/action_sheet.dart';

/// Secondary playback tools under the Now Playing controls: queue, sleep
/// timer and playback speed, each with a 44 px touch target.
class PlayerUtilityDock extends StatelessWidget {
  const PlayerUtilityDock({super.key});

  static const height = 44.0;

  static const _speeds = [0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    final sigma = GlassTheme.nowPlaying(context).blurSigma;
    final body = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DockItem(
            icon: LucideIcons.listMusic,
            label: context.l10n.queueTitle,
            onTap: () {
              AppHaptics.selectionClick();
              showQueueSheet(context);
            },
          ),
          BlocBuilder<SleepTimerCubit, SleepTimerState>(
            builder: (context, timer) => _DockItem(
              icon: LucideIcons.timer,
              label: context.l10n.sleepTimer,
              isActive: timer is! SleepTimerOff,
              onTap: () {
                AppHaptics.selectionClick();
                _showTimerSheet(context);
              },
            ),
          ),
          BlocSelector<PlayerBloc, PlayerState, double>(
            selector: (s) => s is PlayerActive ? s.speed : 1.0,
            builder: (context, speed) => _DockItem(
              icon: LucideIcons.gauge,
              label: context.l10n.playbackSpeed,
              isActive: speed != 1.0,
              badgeText: speed != 1.0 ? _formatSpeed(speed) : null,
              onTap: () {
                AppHaptics.selectionClick();
                _showSpeedSheet(context, speed);
              },
            ),
          ),
        ],
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: sigma == 0
          ? body
          : RepaintBoundary(
              child: BackdropFilter(filter: GlassFilter.of(sigma), child: body),
            ),
    );
  }

  /// 2.0 -> "2×", 1.5 -> "1.5×", 0.75 -> "0.75×".
  static String _formatSpeed(double speed) =>
      '${speed.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '')}×';

  void _showTimerSheet(BuildContext context) {
    final cubit = context.read<SleepTimerCubit>();
    final state = cubit.state;
    final l10n = context.l10n;
    final subtitle = switch (state) {
      SleepTimerRunning(:final endsAt) => l10n.sleepStopsAt(
        MaterialLocalizations.of(
          context,
        ).formatTimeOfDay(TimeOfDay.fromDateTime(endsAt)),
      ),
      SleepTimerEndOfTrack() => l10n.sleepStopsEndOfSong,
      SleepTimerOff() => l10n.sleepIdle,
    };
    final options = <(String, VoidCallback)>[
      for (final minutes in [15, 30, 45])
        (
          l10n.durationMinutes(minutes),
          () => cubit.startFor(Duration(minutes: minutes)),
        ),
      (l10n.sleepOneHour, () => cubit.startFor(const Duration(hours: 1))),
      (l10n.sleepEndOfSong, cubit.startEndOfTrack),
      if (state is! SleepTimerOff) (l10n.sleepTurnOff, cubit.cancel),
    ];

    showActionSheet(
      context,
      title: l10n.sleepTimer,
      message: subtitle,
      actions: [
        for (final (label, action) in options)
          SheetAction(label: label, onPressed: action),
      ],
    );
  }

  void _showSpeedSheet(BuildContext context, double current) {
    final bloc = context.read<PlayerBloc>();
    showActionSheet(
      context,
      title: context.l10n.playbackSpeed,
      actions: [
        for (final speed in _speeds)
          SheetAction(
            label: speed == 1.0
                ? context.l10n.playbackSpeedNormal(_formatSpeed(speed))
                : _formatSpeed(speed),
            selected: speed == current,
            onPressed: () => bloc.add(SpeedChangeRequested(speed)),
          ),
      ],
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final String? badgeText;

  const _DockItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Tooltip(
      message: label,
      preferBelow: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: SizedBox(
            width: 52,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  semanticLabel: label,
                  color: isActive
                      ? colors.accent
                      : Colors.white.withValues(alpha: 0.72),
                ),
                if (isActive)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: badgeText != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: colors.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText!,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: colors.accentForeground,
                              ),
                            ),
                          )
                        : Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: colors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
