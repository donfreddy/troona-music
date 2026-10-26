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
  final List<ReleaseNote> notes;

  const Release(this.version, this.notes);

  List<ReleaseNote> ofKind(ReleaseNoteKind kind) => [
    for (final n in notes)
      if (n.kind == kind) n,
  ];
}

/// Every release with notes, newest first. To ship notes with an update,
/// add its entry here (strings in the l10n sources): "What's new" then opens
/// once after the update. A version without an entry updates silently.
List<Release> releaseNotes(AppLocalizations l10n) => [
  Release('1.0.0', [
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
      l10n.whatsNew100QueueTitle,
      l10n.whatsNew100QueueBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.added,
      l10n.whatsNew100ExtrasTitle,
      l10n.whatsNew100ExtrasBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.improved,
      l10n.whatsNew100LibraryTitle,
      l10n.whatsNew100LibraryBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.improved,
      l10n.whatsNew100ShuffleTitle,
      l10n.whatsNew100ShuffleBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.improved,
      l10n.whatsNew100LanguageTitle,
      l10n.whatsNew100LanguageBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.fixed,
      l10n.whatsNew100LockTitle,
      l10n.whatsNew100LockBody,
    ),
    ReleaseNote(
      ReleaseNoteKind.fixed,
      l10n.whatsNew100ToastTitle,
      l10n.whatsNew100ToastBody,
    ),
  ]),
];

/// The notes of [version], or of the newest release when it has none (a
/// hotfix build opened from Settings still shows something).
Release releaseFor(AppLocalizations l10n, String? version) {
  final all = releaseNotes(l10n);
  return all.firstWhere((r) => r.version == version, orElse: () => all.first);
}
