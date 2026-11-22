import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/utils/app_logger.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics.dart';
import 'package:troona/features/lyrics/domain/services/lrc_parser.dart';
import 'package:troona/features/lyrics/presentation/cubit/lyrics_cubit.dart';
import 'package:troona/features/lyrics/presentation/cubit/lyrics_state.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/action_sheet.dart';
import 'package:troona/shared/widgets/app_dialog.dart';
import 'package:troona/shared/widgets/app_toast.dart';

/// Picks a lyrics file and keeps it for the song playing. Any file is
/// offered: `.lrc` has no type Android knows, and a filter would hide it.
/// The file is checked once read.
Future<void> importLyrics(BuildContext context, LyricsCubit cubit) async {
  final l10n = context.l10n;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  final FilePickerResult? picked;
  try {
    picked = await FilePicker.pickFiles();
  } catch (e) {
    appLogger.w('Lyrics file picker failed: $e');
    return;
  }
  final path = picked?.files.singleOrNull?.path;
  if (path == null) return;
  var ok = false;
  try {
    final file = File(path);
    if (await file.length() <= LrcParser.maxBytes) {
      ok = await cubit.import(await file.readAsBytes());
    }
  } catch (e) {
    appLogger.w('Lyrics file unreadable: $e');
  } finally {
    unawaited(FilePicker.clearTemporaryFiles());
  }
  if (overlay == null) return;
  AppToast.showOn(overlay, ok ? l10n.lyricsImported : l10n.lyricsImportInvalid);
}

/// Says what the online search sends, turns it on once agreed, and
/// searches.
Future<void> enableLyricsSearch(BuildContext context, LyricsCubit cubit) async {
  final l10n = context.l10n;
  final agreed = await showConfirmDialog(
    context,
    title: l10n.lyricsEnableTitle,
    body: l10n.lyricsEnableBody,
    confirmLabel: l10n.lyricsEnableAction,
  );
  if (!agreed) return;
  await getIt<SettingsCubit>().setFetchLyrics(true);
  await cubit.searchOnline();
}

/// The lyrics menu: import, search again, timing, remove, and where they
/// come from.
void showLyricsOptions(BuildContext context, LyricsCubit cubit) {
  final l10n = context.l10n;
  final state = cubit.state;
  final shown = state is LyricsShown ? state : null;
  final synced = shown?.lyrics is SyncedLyrics;
  final online = switch (state) {
    LyricsShown() => true,
    LyricsNone(:final onlineEnabled) => onlineEnabled,
    _ => false,
  };
  final source = switch (shown?.lyrics.source) {
    LyricsSource.imported => l10n.lyricsSourceImported,
    LyricsSource.online => l10n.lyricsSourceOnline,
    _ => null,
  };
  showActionSheet(
    context,
    title: l10n.lyricsTitle,
    message: [
      ?source,
      if (synced) l10n.lyricsOffsetValue(_seconds(shown!.offset, l10n)),
    ].join('\n'),
    actions: [
      SheetAction(
        label: l10n.lyricsImport,
        icon: AppIcons.lyricsImport,
        onPressed: () => importLyrics(context, cubit),
      ),
      if (online)
        SheetAction(
          label: l10n.lyricsSearchAgain,
          icon: AppIcons.lyricsSearch,
          onPressed: () => unawaited(cubit.searchOnline()),
        ),
      if (synced) ...[
        SheetAction(
          label: l10n.lyricsEarlier,
          icon: AppIcons.lyricsTiming,
          onPressed: () => _nudge(context, cubit, 1),
        ),
        SheetAction(
          label: l10n.lyricsLater,
          icon: AppIcons.lyricsTiming,
          onPressed: () => _nudge(context, cubit, -1),
        ),
        if (shown!.offset != Duration.zero)
          SheetAction(
            label: l10n.lyricsOffsetReset,
            icon: AppIcons.reset,
            onPressed: () =>
                cubit.nudgeOffset(-shown.offset.inMilliseconds ~/ 100),
          ),
      ],
      if (shown != null)
        SheetAction(
          label: l10n.lyricsRemove,
          icon: AppIcons.lyricsRemove,
          destructive: true,
          onPressed: () => _remove(context, cubit),
        ),
    ],
  );
}

/// One step, then the menu again with the new value: a timing is set by
/// several steps in a row.
void _nudge(BuildContext context, LyricsCubit cubit, int steps) {
  cubit.nudgeOffset(steps);
  if (context.mounted) showLyricsOptions(context, cubit);
}

Future<void> _remove(BuildContext context, LyricsCubit cubit) async {
  final l10n = context.l10n;
  final confirmed = await showConfirmDialog(
    context,
    title: l10n.lyricsRemoveTitle,
    body: l10n.lyricsRemoveBody,
    confirmLabel: l10n.lyricsRemove,
    destructive: true,
  );
  if (confirmed) await cubit.delete();
}

/// "+0.3", "-1.2", "0.0", with the locale's decimal mark.
String _seconds(Duration offset, AppLocalizations l10n) {
  final value = (offset.inMilliseconds / 1000).toStringAsFixed(1);
  final signed = offset > Duration.zero ? '+$value' : value;
  return l10n.localeName == 'fr' ? signed.replaceAll('.', ',') : signed;
}
