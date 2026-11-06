import 'package:flutter/material.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/shared/widgets/app_back_button.dart';
import 'package:troona/shared/widgets/glass_sliver_header.dart';

/// In-app privacy policy. Mirrors `docs/privacy-policy.md`, the page linked
/// from the store listings: keep both in sync.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final sections = [
      (l10n.privacyLocalTitle, l10n.privacyLocalBody),
      (l10n.privacyOnlineTitle, l10n.privacyOnlineBody),
      (l10n.privacyUpdatesTitle, l10n.privacyUpdatesBody),
      (l10n.privacyReportsTitle, l10n.privacyReportsBody),
      (l10n.privacyBackupTitle, l10n.privacyBackupBody),
      (l10n.privacyDeleteTitle, l10n.privacyDeleteBody),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          GlassSliverHeader.largeTitle(
            leading: const AppBackButton(),
            title: l10n.privacyTitle,
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              context.bottomBarInset(tabs: false),
            ),
            sliver: SliverList.list(
              children: [
                Text(
                  l10n.privacyIntro,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.4,
                    color: colors.labelPrimary,
                  ),
                ),
                for (final (title, body) in sections) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.labelPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: colors.labelSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
