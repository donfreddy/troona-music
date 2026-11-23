import 'package:flutter/material.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/backup/presentation/utils/backup_labels.dart';
import 'package:troona/shared/widgets/app_button.dart';
import 'package:troona/shared/widgets/glass_bottom_sheet.dart';

/// Asks which of [parts] to take, [initial] ticked: what a backup holds,
/// or what a restore writes. Null when dismissed. At least one stays
/// ticked: the button waits for one.
Future<Set<BackupPart>?> showBackupPartsSheet(
  BuildContext context, {
  required String title,
  String? message,
  required List<BackupPart> parts,
  required Set<BackupPart> initial,
  String Function(BackupPart part)? detail,
  required String confirmLabel,
}) => showGlassBottomSheet<Set<BackupPart>>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _PartsSheet(
    title: title,
    message: message,
    parts: parts,
    initial: initial,
    detail: detail,
    confirmLabel: confirmLabel,
  ),
);

class _PartsSheet extends StatefulWidget {
  final String title;
  final String? message;
  final List<BackupPart> parts;
  final Set<BackupPart> initial;
  final String Function(BackupPart part)? detail;
  final String confirmLabel;

  const _PartsSheet({
    required this.title,
    required this.message,
    required this.parts,
    required this.initial,
    required this.detail,
    required this.confirmLabel,
  });

  @override
  State<_PartsSheet> createState() => _PartsSheetState();
}

class _PartsSheetState extends State<_PartsSheet> {
  late final Set<BackupPart> _chosen = {
    for (final p in widget.parts)
      if (widget.initial.contains(p)) p,
  };

  void _toggle(BackupPart part) {
    AppHaptics.selectionClick();
    setState(() {
      if (!_chosen.remove(part)) _chosen.add(part);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final l10n = context.l10n;
    final message = widget.message;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  widget.title,
                  style: textTheme.headlineSmall?.copyWith(
                    color: colors.labelPrimary,
                  ),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: textTheme.labelLarge?.copyWith(
                    color: colors.labelSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        Divider(height: 1, color: colors.separator),
        const SizedBox(height: AppSpacing.xs),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final part in widget.parts)
                  _PartRow(
                    icon: partIcon(part),
                    label: l10n.partName(part),
                    detail: widget.detail?.call(part),
                    checked: _chosen.contains(part),
                    onTap: () => _toggle(part),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AppButton.primary(
            widget.confirmLabel,
            expanded: true,
            onPressed: _chosen.isEmpty
                ? null
                : () => Navigator.of(context).pop({..._chosen}),
          ),
        ),
      ],
    );
  }
}

/// A part with its box: a ring, filled with a check once ticked.
class _PartRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? detail;
  final bool checked;
  final VoidCallback onTap;

  const _PartRow({
    required this.icon,
    required this.label,
    required this.detail,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final detail = this.detail;
    return Semantics(
      checked: checked,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: colors.labelSecondary),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.labelPrimary,
                          ),
                        ),
                        if (detail != null)
                          Text(
                            detail,
                            style: textTheme.labelMedium?.copyWith(
                              color: colors.labelSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _Box(checked: checked),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final bool checked;
  const _Box({required this.checked});

  static const double size = 24;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? colors.accent : null,
        border: checked
            ? null
            : Border.all(
                color: colors.labelPrimary.withValues(alpha: .8),
                width: 1.5,
              ),
      ),
      child: checked
          ? Icon(AppIcons.selected, size: 16, color: colors.accentForeground)
          : null,
    );
  }
}
