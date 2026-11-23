import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/settings/presentation/widgets/settings_hue.dart';
import 'package:troona/features/settings/presentation/widgets/settings_section.dart';
import 'package:troona/features/settings/presentation/widgets/settings_subpage.dart';
import 'package:troona/features/settings/presentation/widgets/settings_tile.dart';

/// The questions that come up most, each answered in a sentence or two and
/// opening the setting that settles it. Not a FAQ: only what the app can
/// act on.
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SettingsSubpage(
      title: l10n.helpTitle,
      intro: l10n.helpIntro,
      children: [
        SettingsSection(
          title: l10n.helpLibrarySection,
          children: [
            SettingsTile.navigation(
              icon: AppIcons.helpMissingSong,
              iconColor: SettingsHue.library,
              title: l10n.helpMissingSong,
              subtitle: l10n.helpMissingSongAnswer,
              onTap: () => context.pushNamed(AppRoute.settingsLibrary),
            ),
          ],
        ),
        // Battery saving that stops apps is Android's.
        if (defaultTargetPlatform == TargetPlatform.android)
          SettingsSection(
            title: l10n.helpPlaybackSection,
            children: [
              SettingsTile.navigation(
                icon: AppIcons.helpBattery,
                iconColor: SettingsHue.audio,
                title: l10n.helpStopsInBackground,
                subtitle: l10n.helpStopsInBackgroundAnswer,
                // Battery use is set from the app's page in Android's
                // settings.
                onTap: openAppSettings,
              ),
            ],
          ),
        SettingsSection(
          title: l10n.helpOnlineSection,
          children: [
            SettingsTile.navigation(
              icon: AppIcons.lyrics,
              iconColor: SettingsHue.online,
              title: l10n.helpNoLyrics,
              subtitle: l10n.helpNoLyricsAnswer,
              onTap: () => context.pushNamed(AppRoute.settingsOnline),
            ),
            SettingsTile.navigation(
              icon: AppIcons.settingsOnline,
              iconColor: SettingsHue.online,
              title: l10n.helpArtistInfo,
              subtitle: l10n.helpArtistInfoAnswer,
              onTap: () => context.pushNamed(AppRoute.settingsOnline),
            ),
          ],
        ),
        SettingsSection(
          title: l10n.helpBackupSection,
          children: [
            SettingsTile.navigation(
              icon: AppIcons.helpPhoneChange,
              iconColor: SettingsHue.backup,
              title: l10n.helpNewPhone,
              subtitle: l10n.helpNewPhoneAnswer,
              onTap: () => context.pushNamed(AppRoute.backup),
            ),
          ],
        ),
      ],
    );
  }
}
