import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:go_router/go_router.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/settings/presentation/utils/license_catalog.dart';
import 'package:troona/features/settings/presentation/widgets/settings_hue.dart';
import 'package:troona/features/settings/presentation/widgets/settings_section.dart';
import 'package:troona/features/settings/presentation/widgets/settings_subpage.dart';
import 'package:troona/features/settings/presentation/widgets/settings_tile.dart';
import 'package:troona/l10n/app_localizations.dart';

/// What a group is called in the list: its package, or its first one and
/// how many more.
String licenseTitleOf(AppLocalizations l10n, LicenseGroup group) =>
    switch (group.packages) {
      [final only] => only,
      [final first, ...final rest] => l10n.licensesTitleMore(
        first,
        rest.length,
      ),
      [] => l10n.settingsLicenses,
    };

/// The open-source licenses, in the app's own pages rather than Flutter's
/// stock [LicensePage]: one row per license text, the packages it covers
/// named on it, each opening on its own page.
class LicensesPage extends StatefulWidget {
  const LicensesPage({super.key});

  @override
  State<LicensesPage> createState() => _LicensesPageState();
}

class _LicensesPageState extends State<LicensesPage> {
  late final Future<List<LicenseGroup>> _groups = LicenseCatalog.load();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SettingsSubpage(
      title: l10n.settingsLicenses,
      intro: l10n.licensesIntro,
      children: [
        FutureBuilder<List<LicenseGroup>>(
          future: _groups,
          builder: (context, snapshot) {
            final groups = snapshot.data;
            if (snapshot.hasError) return _Note(l10n.errorGeneric);
            if (groups == null) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CupertinoActivityIndicator(),
              );
            }
            return SettingsSection(
              title: l10n.licensesSection,
              children: [
                for (final (i, group) in groups.indexed)
                  SettingsTile.navigation(
                    icon: AppIcons.licenses,
                    iconColor: SettingsHue.about,
                    title: licenseTitleOf(l10n, group),
                    subtitle: group.kind ?? l10n.licensesOwnTerms,
                    onTap: () => context.pushNamed(
                      AppRoute.settingsLicense,
                      pathParameters: {'index': '$i'},
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// One license text. Found by its place in [LicenseCatalog], read once per
/// process, so the route holds a plain number.
class LicenseDetailPage extends StatefulWidget {
  final int index;

  const LicenseDetailPage({super.key, required this.index});

  @override
  State<LicenseDetailPage> createState() => _LicenseDetailPageState();
}

class _LicenseDetailPageState extends State<LicenseDetailPage> {
  late final Future<List<LicenseGroup>> _groups = LicenseCatalog.load();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<List<LicenseGroup>>(
      future: _groups,
      builder: (context, snapshot) {
        final groups = snapshot.data;
        final group = groups != null && widget.index < groups.length
            ? groups.elementAtOrNull(widget.index)
            : null;
        if (group == null) {
          return SettingsSubpage(
            title: l10n.settingsLicenses,
            children: [
              if (snapshot.connectionState == ConnectionState.done)
                _Note(l10n.licensesNotFound)
              else
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CupertinoActivityIndicator(),
                ),
            ],
          );
        }
        // One child per paragraph: a long text (some hold thousands) is
        // built as it scrolls in, never all at once.
        return SettingsSubpage(
          title: group.packages.length == 1
              ? group.packages.single
              : group.kind ?? l10n.settingsLicenses,
          intro: group.packages.join(', '),
          children: [
            const SizedBox(height: AppSpacing.md),
            for (final p in group.paragraphs) _Paragraph(p),
          ],
        );
      },
    );
  }
}

class _Paragraph extends StatelessWidget {
  final LicenseParagraph paragraph;

  const _Paragraph(this.paragraph);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final centred = paragraph.indent == LicenseParagraph.centeredIndent;
    final indent = centred ? 0.0 : 16.0 * paragraph.indent;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg + indent,
        centred ? AppSpacing.md : AppSpacing.xs,
        AppSpacing.lg,
        0,
      ),
      child: SelectableText(
        paragraph.text,
        textAlign: centred ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          fontSize: 13,
          height: 1.45,
          fontWeight: centred ? FontWeight.w600 : FontWeight.w400,
          color: centred ? colors.labelPrimary : colors.labelSecondary,
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;

  const _Note(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Text(
      text,
      style: TextStyle(fontSize: 15, color: context.colors.labelSecondary),
    ),
  );
}
