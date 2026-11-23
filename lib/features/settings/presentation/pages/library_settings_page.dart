import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/settings/presentation/widgets/settings_hue.dart';
import 'package:troona/features/settings/presentation/widgets/settings_section.dart';
import 'package:troona/features/settings/presentation/widgets/settings_subpage.dart';
import 'package:troona/features/settings/presentation/widgets/settings_tile.dart';

LibraryLoaded? _loaded(LibraryState state) => switch (state) {
  LibraryLoaded() => state,
  LibraryScanning(:final cached?) => cached,
  _ => null,
};

(int, int, int)? _counts(LibraryState state) => switch (_loaded(state)) {
  final l? => (l.allTracks.length, l.allAlbums.length, l.allArtists.length),
  null => null,
};

/// What the library holds, and scanning the phone again.
class LibrarySettingsPage extends StatelessWidget {
  const LibrarySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SettingsSubpage(
      title: l10n.settingsLibrary,
      intro: l10n.settingsLibraryIntro,
      children: [
        BlocBuilder<LibraryBloc, LibraryState>(
          // A scan's progress emits often: only a start, an end or other
          // counts redraw the page.
          buildWhen: (previous, current) =>
              (previous is LibraryScanning) != (current is LibraryScanning) ||
              _counts(previous) != _counts(current),
          builder: (context, state) {
            final library = _loaded(state);
            final scanning = state is LibraryScanning;
            return Column(
              children: [
                if (library != null)
                  SettingsSection(
                    title: l10n.settingsLibraryContents,
                    children: [
                      SettingsTile(
                        icon: AppIcons.library,
                        iconColor: SettingsHue.library,
                        title: l10n.songCount(library.allTracks.length),
                        subtitle: [
                          l10n.albumCount(library.allAlbums.length),
                          l10n.artistCount(library.allArtists.length),
                        ].join(', '),
                      ),
                    ],
                  ),
                SettingsSection(
                  title: l10n.settingsScan,
                  footer: l10n.settingsScanFooter,
                  children: [
                    SettingsTile(
                      icon: AppIcons.refresh,
                      iconColor: SettingsHue.library,
                      title: l10n.settingsRescan,
                      subtitle: scanning
                          ? l10n.settingsRescanning
                          : l10n.settingsRescanSubtitle,
                      trailing: scanning
                          ? const CupertinoActivityIndicator()
                          : null,
                      onTap: scanning
                          ? null
                          : () => context.read<LibraryBloc>().add(
                              const LibraryRefreshRequested(),
                            ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
