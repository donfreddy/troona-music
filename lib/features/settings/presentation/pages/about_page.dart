import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/settings/domain/repositories/maintenance_repository.dart';
import 'package:troona/features/settings/presentation/cubit/maintenance_cubit.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/features/settings/presentation/widgets/settings_builder.dart';
import 'package:troona/features/settings/presentation/widgets/settings_hue.dart';
import 'package:troona/features/settings/presentation/widgets/settings_section.dart';
import 'package:troona/features/settings/presentation/widgets/settings_subpage.dart';
import 'package:troona/features/settings/presentation/widgets/settings_tile.dart';
import 'package:troona/features/updates/presentation/cubit/update_cubit.dart';
import 'package:troona/features/updates/presentation/open_release.dart';
import 'package:troona/features/whats_new/presentation/release_notes.dart';
import 'package:troona/features/whats_new/presentation/widgets/whats_new_sheet.dart';
import 'package:troona/shared/widgets/app_badge.dart';
import 'package:troona/shared/widgets/app_dialog.dart';
import 'package:troona/shared/widgets/app_toast.dart';
import 'package:troona/shared/widgets/glass_card.dart';
import 'package:url_launcher/url_launcher.dart';

/// The app's repository: its releases are where updates come from.
final _source = Uri.https('github.com', '/donfreddy/troona-music');

/// The version, updates, help, and the policies.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  void initState() {
    super.initState();
    // Read by the root already, unless the page was opened some other way.
    final maintenance = context.read<MaintenanceCubit>();
    if (maintenance.state.version == null) unawaited(maintenance.load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final version = context.watch<MaintenanceCubit>().state.version;
    final update = context.watch<UpdateCubit>().state;
    return SettingsSubpage(
      title: l10n.settingsAbout,
      children: [
        _Hero(version: version),
        SettingsSection(
          title: l10n.aboutUpdates,
          children: [
            SettingsBuilder(
              builder: (context, settings) => SettingsTile.switchTile(
                icon: AppIcons.update,
                iconColor: SettingsHue.about,
                title: l10n.settingsUpdateCheck,
                subtitle: l10n.settingsUpdateCheckSubtitle,
                value: settings.checkForUpdates,
                onChanged: (on) => _setCheckForUpdates(context, on),
              ),
            ),
            SettingsTile(
              icon: AppIcons.refresh,
              iconColor: SettingsHue.about,
              title: l10n.updateCheckNow,
              subtitle: switch (update.available) {
                final release? => l10n.updateAvailable(release.version),
                null => null,
              },
              trailing: update.checking
                  ? const CupertinoActivityIndicator()
                  : null,
              onTap: update.checking ? null : () => _checkForUpdate(context),
            ),
            SettingsTile.navigation(
              icon: AppIcons.whatsNew,
              iconColor: SettingsHue.about,
              title: l10n.whatsNewTitle,
              subtitle: version == null
                  ? null
                  : l10n.whatsNewVersion(version.version),
              onTap: () => showWhatsNewSheet(
                context,
                releases: releaseNotes(l10n),
                version: version?.version,
              ),
            ),
          ],
        ),
        SettingsSection(
          title: l10n.settingsSupport,
          children: [
            SettingsTile.navigation(
              icon: AppIcons.report,
              iconColor: SettingsHue.about,
              title: l10n.settingsReport,
              subtitle: l10n.settingsReportSubtitle,
              onTap: () => _shareReport(context),
            ),
          ],
        ),
        SettingsSection(
          title: l10n.aboutInformation,
          children: [
            SettingsTile.navigation(
              icon: AppIcons.privacy,
              iconColor: SettingsHue.about,
              title: l10n.settingsPrivacy,
              onTap: () => context.pushNamed(AppRoute.privacy),
            ),
            SettingsTile.navigation(
              icon: AppIcons.sourceCode,
              iconColor: SettingsHue.about,
              title: l10n.aboutSource,
              subtitle: l10n.aboutSourceSubtitle,
              onTap: () => _openSource(context),
            ),
            SettingsTile.navigation(
              icon: AppIcons.licenses,
              iconColor: SettingsHue.about,
              title: l10n.settingsLicenses,
              subtitle: l10n.settingsLicensesSubtitle,
              onTap: () => context.pushNamed(AppRoute.settingsLicenses),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _setCheckForUpdates(BuildContext context, bool on) async {
    final updates = context.read<UpdateCubit>();
    await context.read<SettingsCubit>().setCheckForUpdates(on);
    on ? await updates.checkIfEnabled() : updates.clear();
  }

  /// Asks GitHub; a newer release is offered in a dialog, even a skipped
  /// one, since the user asked.
  Future<void> _checkForUpdate(BuildContext context) async {
    final l10n = context.l10n;
    final overlay = Overlay.of(context, rootOverlay: true);
    final result = await context.read<UpdateCubit>().checkNow();
    final release = result.fold((_) => null, (release) => release);
    if (release == null) {
      final failed = result.isLeft();
      AppToast.showOn(
        overlay,
        failed ? l10n.updateCheckFailed : l10n.updateUpToDate,
      );
      return;
    }
    if (!context.mounted) return;
    final view = await showConfirmDialog(
      context,
      title: l10n.updateAvailable(release.version),
      body: l10n.updateAvailableBody,
      confirmLabel: l10n.updateView,
    );
    if (view && context.mounted) await openRelease(context, release);
  }

  Future<void> _shareReport(BuildContext context) async {
    final l10n = context.l10n;
    final library = context.read<LibraryBloc>().state;
    final trackCount = switch (library) {
      LibraryLoaded(:final allTracks) => allTracks.length,
      LibraryScanning(:final cached?) => cached.allTracks.length,
      _ => 0,
    };
    final report = await context.read<MaintenanceCubit>().problemReport(
      trackCount: trackCount,
    );
    await SharePlus.instance.share(
      ShareParams(text: report, subject: l10n.settingsReportSubject),
    );
  }

  Future<void> _openSource(BuildContext context) async {
    final failed = context.l10n.updateOpenFailed;
    final overlay = Overlay.of(context, rootOverlay: true);
    final opened = await launchUrl(
      _source,
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);
    if (!opened) AppToast.showOn(overlay, failed);
  }
}

/// The logo, the name, the version and the tagline.
class _Hero extends StatelessWidget {
  final AppVersion? version;

  const _Hero({required this.version});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final v = version;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        0,
      ),
      child: GlassCard(
        config: GlassTheme.content(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: Image.asset(
                  'assets/images/app-logo.png',
                  width: 72,
                  height: 72,
                  cacheWidth: 216,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.appName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colors.labelPrimary,
                ),
              ),
              if (v != null) ...[
                const SizedBox(height: AppSpacing.sm),
                AppBadge(l10n.aboutVersion(v.version, v.build)),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.settingsTagline,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colors.labelSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
