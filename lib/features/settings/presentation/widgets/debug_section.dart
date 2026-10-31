import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/history/domain/repositories/monthly_replay_log.dart';
import 'package:troona/features/history/domain/use_cases/create_monthly_replay_use_case.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/settings/presentation/widgets/settings_section.dart';
import 'package:troona/features/settings/presentation/widgets/settings_tile.dart';
import 'package:troona/features/whats_new/domain/repositories/whats_new_repository.dart';
import 'package:troona/shared/widgets/app_toast.dart';

/// Shortcuts to test once-a-month and once-per-update flows without waiting
/// for them. Debug and profile builds only (the caller checks kReleaseMode),
/// so the strings are not localized.
class DebugSection extends StatelessWidget {
  const DebugSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Debug',
      children: [
        SettingsTile(
          icon: AppIcons.monthlyReplay,
          iconColor: const Color(0xFFF59E0B),
          title: 'Replay this month now',
          subtitle: 'Makes the Replay of the current month, as if it ended',
          onTap: () => _replayThisMonth(context),
        ),
        SettingsTile(
          icon: AppIcons.whatsNew,
          iconColor: const Color(0xFFF59E0B),
          title: 'Show What\'s new on next launch',
          subtitle: 'As after an update from an older version',
          onTap: () => _resetWhatsNew(context),
        ),
      ],
    );
  }

  /// A second tap during a run would save a second Replay, and could
  /// restore the log last with this month marked as handled.
  static bool _replayRunning = false;

  Future<void> _replayThisMonth(BuildContext context) async {
    if (_replayRunning) return;
    _replayRunning = true;
    final l10n = context.l10n;
    final monthName = DateFormat.yMMMM(
      Localizations.localeOf(context).toString(),
    );
    final log = getIt<MonthlyReplayLog>();
    final now = DateTime.now();
    final thisMonth = now.year * 12 + now.month - 1;
    final previous = log.lastMonth;
    final Either<Failure, Playlist?> result;
    try {
      // The use case covers the month before `now`: run it as of next
      // month, and let it through even when an earlier tap handled this
      // month.
      await log.setLastMonth(thisMonth - 1);
      result = await getIt<CreateMonthlyReplayUseCase>()(
        now: DateTime(now.year, now.month + 1),
        name: (month) => l10n.replayName(monthName.format(month)),
      );
    } finally {
      // Back to the real state, so the first launch of next month still
      // makes its own Replay. The log cannot be cleared: when this month's
      // launch saved nothing (null), last month counts as handled from here.
      await log.setLastMonth(previous ?? thisMonth - 1);
      _replayRunning = false;
    }
    if (!context.mounted) return;
    final message = result.fold(
      (failure) => 'Replay failed: $failure',
      (playlist) => playlist == null
          ? 'Not enough songs played this month '
                '(${CreateMonthlyReplayUseCase.minTracks} needed)'
          : l10n.replayReady(playlist.name),
    );
    AppToast.show(context, message);
  }

  Future<void> _resetWhatsNew(BuildContext context) async {
    // Any version other than the current one: the next launch sees an
    // update and opens the current version's notes.
    await getIt<WhatsNewRepository>().setLastSeenVersion('0.0.0');
    if (!context.mounted) return;
    AppToast.show(context, 'Restart the app to see What\'s new');
  }
}
