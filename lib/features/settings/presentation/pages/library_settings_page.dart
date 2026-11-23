import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/settings/presentation/widgets/settings_hue.dart';
import 'package:troona/features/settings/presentation/widgets/settings_section.dart';
import 'package:troona/features/settings/presentation/widgets/settings_subpage.dart';
import 'package:troona/features/settings/presentation/widgets/settings_tile.dart';

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
          builder: (context, state) {
            final library = switch (state) {
              LibraryLoaded() => state,
              LibraryScanning(:final cached?) => cached,
              _ => null,
            };
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
