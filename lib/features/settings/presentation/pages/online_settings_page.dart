import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/features/settings/presentation/widgets/settings_builder.dart';
import 'package:troona/features/settings/presentation/widgets/settings_hue.dart';
import 'package:troona/features/settings/presentation/widgets/settings_section.dart';
import 'package:troona/features/settings/presentation/widgets/settings_subpage.dart';
import 'package:troona/features/settings/presentation/widgets/settings_tile.dart';
import 'package:troona/l10n/app_localizations.dart';

/// What the root row says of the online extras: off, or the ones on.
String onlineSummary(AppLocalizations l10n, AppSettings settings) {
  final on = [
    if (settings.fetchOnlineMetadata) l10n.settingsOnlineBiosShort,
    if (settings.fetchArtistArtwork) l10n.settingsOnlinePhotosShort,
    if (settings.fetchLyrics) l10n.settingsOnlineLyricsShort,
  ];
  return on.isEmpty
      ? l10n.settingsOnlineOff
      : l10n.settingsOnlineOn(on.join(', '));
}

/// The opt-in extras, each saying what it sends and to whom.
class OnlineSettingsPage extends StatelessWidget {
  const OnlineSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SettingsCubit>();
    return SettingsSubpage(
      title: l10n.settingsOnline,
      intro: l10n.settingsOnlineIntro,
      children: [
        SettingsBuilder(
          builder: (context, settings) => SettingsSection(
            title: l10n.settingsOnlineSources,
            footer: l10n.settingsOnlinePageFooter,
            children: [
              SettingsTile.switchTile(
                icon: AppIcons.biographies,
                iconColor: SettingsHue.online,
                title: l10n.settingsOnlineBios,
                subtitle: l10n.settingsOnlineBiosSubtitle,
                value: settings.fetchOnlineMetadata,
                onChanged: cubit.setFetchOnlineMetadata,
              ),
              SettingsTile.switchTile(
                icon: AppIcons.photos,
                iconColor: SettingsHue.online,
                title: l10n.settingsOnlinePhotos,
                subtitle: l10n.settingsOnlinePhotosSubtitle,
                value: settings.fetchArtistArtwork,
                onChanged: cubit.setFetchArtistArtwork,
              ),
              SettingsTile.switchTile(
                icon: AppIcons.lyrics,
                iconColor: SettingsHue.online,
                title: l10n.settingsOnlineLyrics,
                subtitle: l10n.settingsOnlineLyricsSubtitle,
                value: settings.fetchLyrics,
                onChanged: cubit.setFetchLyrics,
              ),
            ],
          ),
        ),
        SettingsSection(
          title: l10n.settingsPrivacySection,
          children: [
            SettingsTile.navigation(
              icon: AppIcons.privacy,
              iconColor: SettingsHue.online,
              title: l10n.settingsPrivacy,
              onTap: () => context.pushNamed(AppRoute.privacy),
            ),
          ],
        ),
      ],
    );
  }
}
