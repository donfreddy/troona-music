import 'package:troona/l10n/app_localizations.dart';

enum ReleaseNoteKind { added, improved, fixed }

final class ReleaseNote {
  final ReleaseNoteKind kind;
  final String title;
  final String body;

  const ReleaseNote(this.kind, this.title, this.body);
}

final class Release {
  /// As in pubspec.yaml, without the build number.
  final String version;

  /// The day it was published, as in CHANGELOG.md.
  final DateTime date;
  final List<ReleaseNote> notes;

  const Release(this.version, this.notes, {required this.date});

  List<ReleaseNote> ofKind(ReleaseNoteKind kind) => [
    for (final n in notes)
      if (n.kind == kind) n,
  ];
}

/// Every release with notes, newest first. To ship notes with an update,
/// add its entry here (strings in the l10n sources): "What's new" then opens
/// once after the update. A version without an entry updates silently.
List<Release> releaseNotes(AppLocalizations l10n) => [
  Release('1.2.0', date: DateTime(2026, 10, 31), [
    ReleaseNote(
      ReleaseNoteKind.added,
      l10n.whatsNew120ArtistsTitle,
      l10n.whatsNew120ArtistsBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.added,
      l10n.whatsNew120UndoTitle,
      l10n.whatsNew120UndoBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.improved,
      l10n.whatsNew120MenusTitle,
      l10n.whatsNew120MenusBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.improved,
      l10n.whatsNew120LookTitle,
      l10n.whatsNew120LookBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.fixed,
      l10n.whatsNew120PagesTitle,
      l10n.whatsNew120PagesBody,
    ),
  ]),
  Release('1.1.1', date: DateTime(2026, 10, 31), [
    ReleaseNote(
      ReleaseNoteKind.improved,
      l10n.whatsNew111ChangelogTitle,
      l10n.whatsNew111ChangelogBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.fixed,
      l10n.whatsNew111StartupTitle,
      l10n.whatsNew111StartupBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.fixed,
      l10n.whatsNew111HomeTitle,
      l10n.whatsNew111HomeBody,
    ),
  ]),
  Release('1.1.0', date: DateTime(2026, 10, 30), [
    ReleaseNote(
      ReleaseNoteKind.added,
      l10n.whatsNew110BackupTitle,
      l10n.whatsNew110BackupBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.added,
      l10n.whatsNew110UpdatesTitle,
      l10n.whatsNew110UpdatesBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.added,
      l10n.whatsNew110ControlsTitle,
      l10n.whatsNew110ControlsBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.added,
      l10n.whatsNew110RenameTitle,
      l10n.whatsNew110RenameBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.improved,
      l10n.whatsNew110ScreensTitle,
      l10n.whatsNew110ScreensBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.fixed,
      l10n.whatsNew110NotificationTitle,
      l10n.whatsNew110NotificationBody,
    ),
  ]),
  // First public release: everything is new, nothing is compared with a
  // version nobody had.
  Release('1.0.0', date: DateTime(2026, 10, 30), [
    ReleaseNote(
      ReleaseNoteKind.added,
      l10n.whatsNew100LibraryTitle,
      l10n.whatsNew100LibraryBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.added,
      l10n.whatsNew100PlayerTitle,
      l10n.whatsNew100PlayerBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.added,
      l10n.whatsNew100QueueTitle,
      l10n.whatsNew100QueueBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.added,
      l10n.whatsNew100PlaylistsTitle,
      l10n.whatsNew100PlaylistsBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.added,
      l10n.whatsNew100WeekTitle,
      l10n.whatsNew100WeekBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.added,
      l10n.whatsNew100ReplayTitle,
      l10n.whatsNew100ReplayBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.added,
      l10n.whatsNew100SleepTitle,
      l10n.whatsNew100SleepBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.added,
      l10n.whatsNew100ExtrasTitle,
      l10n.whatsNew100ExtrasBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.added,
      l10n.whatsNew100LanguageTitle,
      l10n.whatsNew100LanguageBody,
    ),
  ]),
];

/// In [releases] (newest first), the notes of [version], or the newest
/// release when it has none (a hotfix build opened from Settings still
/// shows something).
Release releaseIn(List<Release> releases, String? version) => releases
    .firstWhere((r) => r.version == version, orElse: () => releases.first);
