import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/scan_filter.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/stored_track_repository.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/features/settings/presentation/widgets/settings_builder.dart';
import 'package:troona/features/settings/presentation/widgets/settings_hue.dart';
import 'package:troona/features/settings/presentation/widgets/settings_section.dart';
import 'package:troona/features/settings/presentation/widgets/settings_subpage.dart';
import 'package:troona/features/settings/presentation/widgets/settings_tile.dart';
import 'package:troona/l10n/app_localizations.dart';

/// A folder the page lists: one holding songs of the library, or one left
/// out (whose songs the library no longer holds once it rescanned).
@immutable
final class LibraryFolder {
  final String path;

  /// Songs of the library in it, subfolders not counted.
  final int songs;

  const LibraryFolder(this.path, this.songs);

  String get name => path.substring(path.lastIndexOf('/') + 1);

  @override
  bool operator ==(Object other) =>
      other is LibraryFolder && other.path == path && other.songs == songs;

  @override
  int get hashCode => Object.hash(path, songs);
}

/// The folders holding [songPaths], counted, and every folder in
/// [excluded], sorted by path whatever the case.
List<LibraryFolder> libraryFoldersOf(
  Iterable<String> songPaths,
  Iterable<String> excluded,
) {
  final counts = <String, int>{};
  for (final path in songPaths) {
    final folder = ScanFilter.folderOf(path);
    if (folder.isNotEmpty) counts[folder] = (counts[folder] ?? 0) + 1;
  }
  for (final folder in excluded) {
    if (folder.isNotEmpty) counts.putIfAbsent(folder, () => 0);
  }
  return [for (final e in counts.entries) LibraryFolder(e.key, e.value)]
    ..sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
}

final _sdCard = RegExp(r'^/storage/[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}(?=/|$)');
const _phone = '/storage/emulated/0';

/// Where [folder] lies, said the way people know it: "Phone/Music", "SD
/// card/Albums"; empty for the root of a storage, which its name says. A
/// path elsewhere is shown as it is.
String folderPlace(AppLocalizations l10n, String folder) {
  if (_isRoot(folder)) return '';
  final parent = ScanFilter.folderOf(folder);
  if (parent == _phone || parent.startsWith('$_phone/')) {
    return l10n.settingsFolderInPhone + parent.substring(_phone.length);
  }
  if (_sdCard.firstMatch(parent) case final m?) {
    return l10n.settingsFolderInSdCard + parent.substring(m.end);
  }
  return parent.isEmpty ? '/' : parent;
}

/// A folder's name; the root of a storage is named after it ("Phone"),
/// not "0".
String folderNameOf(AppLocalizations l10n, String folder) {
  if (folder == _phone) return l10n.settingsFolderInPhone;
  if (_sdCard.firstMatch(folder)?.end == folder.length) {
    return l10n.settingsFolderInSdCard;
  }
  return folder.substring(folder.lastIndexOf('/') + 1);
}

bool _isRoot(String folder) =>
    folder == _phone || _sdCard.firstMatch(folder)?.end == folder.length;

/// Turns folders of the library on and off, saved at once: the shell
/// rescans once the switches settle (`ScanFilterWatch`). Counts are the
/// songs stored, the ones left out included.
class LibraryFoldersPage extends StatefulWidget {
  final StoredTrackRepository stored;

  const LibraryFoldersPage({super.key, required this.stored});

  @override
  State<LibraryFoldersPage> createState() => _LibraryFoldersPageState();
}

class _LibraryFoldersPageState extends State<LibraryFoldersPage> {
  /// Every song stored; null while read, or when the read failed ([_failed]).
  List<Track>? _tracks;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_read());
  }

  Future<void> _read() async {
    final result = await widget.stored.getStoredTracks();
    if (!mounted) return;
    setState(() {
      _tracks = result.fold((_) => _tracks, (t) => t.all);
      _failed = result.isLeft() && _tracks == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tracks = _tracks;
    return SettingsSubpage(
      title: l10n.settingsFolders,
      intro: l10n.settingsFoldersIntro,
      children: [
        // A scan finding new files, or files gone, changes the counts.
        BlocListener<LibraryBloc, LibraryState>(
          listenWhen: (previous, current) =>
              previous is LibraryScanning && current is LibraryLoaded,
          listener: (_, _) => unawaited(_read()),
          child: SettingsBuilder(
            builder: (context, settings) {
              if (tracks == null) {
                return _failed ? _Note(l10n.errorGeneric) : const _Loading();
              }
              final folders = libraryFoldersOf(
                tracks.map((t) => t.path),
                settings.excludedFolders,
              );
              if (folders.isEmpty) return _Note(l10n.settingsFoldersEmpty);
              return _FolderList(
                folders: folders,
                tracks: tracks,
                filter: scanFilterOf(settings),
                onChanged: (folder, {required included}) {
                  final excluded = {...settings.excludedFolders};
                  if (included) {
                    excluded.remove(folder);
                  } else {
                    // Its subfolders go with it: no need to keep them.
                    excluded
                      ..removeWhere((f) => f.startsWith('$folder/'))
                      ..add(folder);
                  }
                  unawaited(
                    context.read<SettingsCubit>().setExcludedFolders(excluded),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FolderList extends StatelessWidget {
  final List<LibraryFolder> folders;
  final List<Track> tracks;
  final ScanFilter filter;
  final void Function(String folder, {required bool included}) onChanged;

  const _FolderList({
    required this.folders,
    required this.tracks,
    required this.filter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kept = [
      for (final t in tracks)
        if (filter.allows(path: t.path, durationMs: t.durationMs)) t.path,
    ];
    return SettingsSection(
      title: l10n.settingsFoldersSection,
      footer: filter.leavesOutEvery(tracks)
          ? '${l10n.settingsFiltersNotApplied} ${l10n.settingsFoldersFooter}'
          : l10n.settingsFoldersFooter,
      children: [
        for (final folder in folders)
          Builder(
            builder: (context) {
              final on = !filter.excludes(folder.path);
              final above = filter.excludedAbove(folder.path);
              // Turning it off must leave a song in the library (a scan
              // finding none reads as songs lost), its subfolders counted.
              final leavesSome =
                  !on ||
                  kept.any(
                    (p) => p != folder.path && !p.startsWith('${folder.path}/'),
                  );
              final status = switch (above) {
                final a? => l10n.settingsFolderCoveredBy(folderNameOf(l10n, a)),
                null => l10n.songCount(folder.songs),
              };
              final place = folderPlace(l10n, folder.path);
              return SettingsTile.switchTile(
                key: ValueKey(folder.path),
                icon: AppIcons.folder,
                iconColor: SettingsHue.library,
                title: folderNameOf(l10n, folder.path),
                subtitle: place.isEmpty ? status : '$status, $place',
                value: on,
                enabled: above == null && leavesSome,
                onChanged: (value) => onChanged(folder.path, included: value),
              );
            },
          ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(AppSpacing.xl),
    child: Center(child: CupertinoActivityIndicator()),
  );
}

class _Note extends StatelessWidget {
  final String text;

  const _Note(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Text(
      text,
      style: TextStyle(fontSize: 15, color: context.colors.labelSecondary),
    ),
  );
}
