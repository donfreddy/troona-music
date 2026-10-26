import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/whats_new/presentation/release_notes.dart';
import 'package:troona/shared/widgets/glass_bottom_sheet.dart';

/// Opens "What's new" for [release] above the mini player and the tab bar.
/// Glass on high-tier devices only: the tab bar already blurs below it.
Future<void> showWhatsNewSheet(BuildContext context, Release release) =>
    showGlassBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      quality: GlassTheme.aboveGlass(context),
      builder: (_) => WhatsNewSheet(release: release),
    );

/// Release notes in the style of a system update page: title, version, then
/// one section per kind of change. Long notes scroll; the button stays.
class WhatsNewSheet extends StatelessWidget {
  final Release release;

  const WhatsNewSheet({super.key, required this.release});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.whatsNewTitle,
              style: TextStyle(
                color: colors.labelPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Text(
            l10n.whatsNewVersion(release.version),
            style: TextStyle(color: colors.labelSecondary, fontSize: 15),
          ),
          const SizedBox(height: AppSpacing.lg),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final kind in ReleaseNoteKind.values)
                    if (release.ofKind(kind) case final notes
                        when notes.isNotEmpty)
                      _Section(kind: kind, notes: notes),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.accentForeground,
              minimumSize: const Size.fromHeight(48),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(l10n.whatsNewContinue),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final ReleaseNoteKind kind;
  final List<ReleaseNote> notes;

  const _Section({required this.kind, required this.notes});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final (label, icon, tint) = switch (kind) {
      ReleaseNoteKind.added => (
        l10n.whatsNewAdded,
        LucideIcons.sparkles,
        colors.accent,
      ),
      ReleaseNoteKind.improved => (
        l10n.whatsNewImproved,
        LucideIcons.zap,
        const Color(0xFF0EA5E9),
      ),
      ReleaseNoteKind.fixed => (
        l10n.whatsNewFixed,
        LucideIcons.wrench,
        const Color(0xFF22C55E),
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(icon, size: 16, color: tint),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: TextStyle(
                    color: tint,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          for (final note in notes)
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.md,
                left: 28 + AppSpacing.sm,
              ),
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: TextStyle(
                        color: colors.labelPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note.body,
                      style: TextStyle(
                        color: colors.labelSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
