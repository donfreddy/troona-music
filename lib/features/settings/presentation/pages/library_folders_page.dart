import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/scan_filter.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
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
/// card/Albums". A path elsewhere is shown as it is.
String folderPlace(AppLocalizations l10n, String folder) {
  final parent = ScanFilter.folderOf(folder);
  if (parent == _phone || parent.startsWith('$_phone/')) {
    return l10n.settingsFolderInPhone + parent.substring(_phone.length);
  }
  if (_sdCard.firstMatch(parent) case final m?) {
    return l10n.settingsFolderInSdCard + parent.substring(m.end);
  }
  return parent.isEmpty ? '/' : parent;
}

/// Turns folders of the library on and off. The choice is saved once, as
/// the page goes (or the app is put away): each save rescans the library.
class LibraryFoldersPage extends StatefulWidget {
  const LibraryFoldersPage({super.key});

  @override
  State<LibraryFoldersPage> createState() => _LibraryFoldersPageState();
}

class _LibraryFoldersPageState extends State<LibraryFoldersPage> {
  late final SettingsCubit _settings;
  late final AppLifecycleListener _lifecycle;

  /// The folders left out as the user is choosing them; null until the
  /// settings are read.
  Set<String>? _excluded;

  @override
  void initState() {
    super.initState();
    _settings = context.read<SettingsCubit>();
    _excluded = _saved()?.toSet();
    _lifecycle = AppLifecycleListener(onHide: _save);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _save();
    super.dispose();
  }

  List<String>? _saved() => switch (_settings.state) {
    SettingsLoaded(:final settings) => settings.excludedFolders,
    _ => null,
  };

  void _save() {
    final excluded = _excluded;
    final saved = _saved();
    if (excluded == null || saved == null || _settings.isClosed) return;
    if (excluded.length == saved.length && excluded.containsAll(saved)) return;
    unawaited(_settings.setExcludedFolders(excluded));
  }

  void _set(String folder, {required bool included}) => setState(() {
    final excluded = _excluded!;
    if (included) {
      excluded.remove(folder);
    } else {
      // Its own subfolders are left out with it: no need to keep them.
      excluded
        ..removeWhere((f) => f.startsWith('$folder/'))
        ..add(folder);
    }
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    _excluded ??= _saved()?.toSet();
    final excluded = _excluded;
    return SettingsSubpage(
      title: l10n.settingsFolders,
      intro: l10n.settingsFoldersIntro,
      children: [
        if (excluded != null)
          BlocBuilder<LibraryBloc, LibraryState>(
            buildWhen: (previous, current) =>
                _tracksOf(previous) != _tracksOf(current),
            builder: (context, state) {
              final folders = libraryFoldersOf(
                _tracksOf(state)?.map((t) => t.path) ?? const [],
                {...excluded, ...?_saved()},
              );
              if (folders.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    l10n.settingsFoldersEmpty,
                    style: TextStyle(
                      fontSize: 15,
                      color: context.colors.labelSecondary,
                    ),
                  ),
                );
              }
              return _FolderList(
                folders: folders,
                filter: ScanFilter(excludedFolders: excluded),
                onChanged: _set,
              );
            },
          ),
      ],
    );
  }

  static List<Track>? _tracksOf(LibraryState state) => switch (state) {
    LibraryLoaded(:final allTracks) => allTracks,
    LibraryScanning(:final cached?) => cached.allTracks,
    _ => null,
  };
}

class _FolderList extends StatelessWidget {
  final List<LibraryFolder> folders;
  final ScanFilter filter;
  final void Function(String folder, {required bool included}) onChanged;

  const _FolderList({
    required this.folders,
    required this.filter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final included = folders.where((f) => !filter.excludes(f.path)).length;
    return SettingsSection(
      title: l10n.settingsFoldersSection,
      footer: l10n.settingsFoldersFooter,
      children: [
        for (final folder in folders)
          Builder(
            builder: (context) {
              final on = !filter.excludes(folder.path);
              final above = filter.excludedAbove(folder.path);
              final status = switch (above) {
                final a? => l10n.settingsFolderCoveredBy(
                  a.substring(a.lastIndexOf('/') + 1),
                ),
                null when on => l10n.songCount(folder.songs),
                null => l10n.settingsFolderExcluded,
              };
              return SettingsTile.switchTile(
                key: ValueKey(folder.path),
                icon: AppIcons.folder,
                iconColor: SettingsHue.library,
                title: folder.name,
                subtitle: '$status, ${folderPlace(l10n, folder.path)}',
                value: on,
                // The last folder in stays: a scan finding nothing would
                // empty the library.
                enabled: above == null && !(on && included == 1),
                onChanged: (value) => onChanged(folder.path, included: value),
              );
            },
          ),
      ],
    );
  }
}
