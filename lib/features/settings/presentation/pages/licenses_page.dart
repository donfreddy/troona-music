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

/// What a package's row says under its name: its licence, or how many it
/// ships when they differ.
String licenseSummaryOf(AppLocalizations l10n, LicensePackage package) =>
    package.kind ??
    (package.texts.length > 1
        ? l10n.licensesCount(package.texts.length)
        : l10n.licensesOwnTerms);

/// The packages in sections by initial, # for the rest; each entry is the
/// package's place in [packages].
List<(String, List<int>)> licenseSectionsOf(List<LicensePackage> packages) {
  final sections = <String, List<int>>{};
  for (final (i, p) in packages.indexed) {
    final first = p.name.isEmpty ? '#' : p.name[0].toUpperCase();
    final key = RegExp('[A-Z]').hasMatch(first) ? first : '#';
    (sections[key] ??= []).add(i);
  }
  return [
    for (final key
        in sections.keys.toList()
          ..sort((a, b) => a == '#' ? 1 : (b == '#' ? -1 : a.compareTo(b))))
      (key, sections[key]!),
  ];
}

/// The open-source licences, in the app's own pages rather than Flutter's
/// stock [LicensePage]: one row per package, in sections by initial built
/// as they scroll in, each opening on its own page.
class LicensesPage extends StatefulWidget {
  const LicensesPage({super.key});

  @override
  State<LicensesPage> createState() => _LicensesPageState();
}

class _LicensesPageState extends State<LicensesPage> {
  late final Future<LicenseIndex> _index = LicenseCatalog.load();
  List<(String, List<int>)>? _sections;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<LicenseIndex>(
      future: _index,
      initialData: LicenseCatalog.loaded,
      builder: (context, snapshot) {
        final index = snapshot.data;
        final sections = index == null
            ? null
            : _sections ??= licenseSectionsOf(index.packages);
        return SettingsSubpage(
          title: l10n.settingsLicenses,
          intro: l10n.licensesIntro,
          slivers: [
            if (index != null && sections != null)
              SliverList.builder(
                itemCount: sections.length,
                itemBuilder: (context, i) {
                  final (letter, places) = sections[i];
                  return SettingsSection(
                    title: letter,
                    children: [
                      for (final place in places)
                        SettingsTile.navigation(
                          icon: AppIcons.licenses,
                          iconColor: SettingsHue.about,
                          title: index.packages[place].name,
                          subtitle: licenseSummaryOf(
                            l10n,
                            index.packages[place],
                          ),
                          onTap: () => context.pushNamed(
                            AppRoute.settingsLicense,
                            pathParameters: {'index': '$place'},
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
          children: [
            if (index == null)
              snapshot.hasError ? _Note(l10n.errorGeneric) : const _Loading(),
          ],
        );
      },
    );
  }
}

/// The licences of one package. Found by its place in [LicenseCatalog],
/// read once per process, so the route holds a plain number.
class LicenseDetailPage extends StatefulWidget {
  final int index;

  const LicenseDetailPage({super.key, required this.index});

  @override
  State<LicenseDetailPage> createState() => _LicenseDetailPageState();
}

class _LicenseDetailPageState extends State<LicenseDetailPage> {
  late final Future<LicenseIndex> _index = LicenseCatalog.load();
  Future<List<List<LicenseParagraph>>>? _paragraphs;

  LicensePackage? _packageIn(LicenseIndex? index) =>
      index?.packages.elementAtOrNull(widget.index);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<LicenseIndex>(
      future: _index,
      initialData: LicenseCatalog.loaded,
      builder: (context, snapshot) {
        final index = snapshot.data;
        final package = widget.index < 0 ? null : _packageIn(index);
        if (index == null || package == null) {
          final done =
              snapshot.connectionState == ConnectionState.done || index != null;
          return SettingsSubpage(
            title: l10n.settingsLicenses,
            children: [done ? _Note(l10n.licensesNotFound) : const _Loading()],
          );
        }
        _paragraphs ??= LicenseCatalog.paragraphsOf(index, package);
        return FutureBuilder<List<List<LicenseParagraph>>>(
          future: _paragraphs,
          builder: (context, split) {
            final texts = split.data;
            final items = <LicenseParagraph?>[
              if (texts != null)
                for (final (i, paragraphs) in texts.indexed) ...[
                  if (i > 0) null,
                  ...paragraphs,
                ],
            ];
            return SettingsSubpage(
              title: package.name,
              intro: licenseSummaryOf(l10n, package),
              // A package may ship hundreds of texts: built as they scroll.
              slivers: [
                SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) => switch (items[i]) {
                    final p? => _Paragraph(p),
                    null => const _Separator(),
                  },
                ),
              ],
              children: [
                if (texts == null)
                  split.hasError ? _Note(l10n.errorGeneric) : const _Loading()
                else
                  const SizedBox(height: AppSpacing.md),
              ],
            );
          },
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
    final indent = centred ? 0.0 : 16.0 * paragraph.indent.clamp(0, 6);
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

/// Between two licence texts of one package.
class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.lg,
    ),
    child: Container(height: 0.5, color: context.colors.hairline),
  );
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(AppSpacing.xl),
    child: CupertinoActivityIndicator(),
  );
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
