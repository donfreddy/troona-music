import 'package:flutter/material.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/shared/widgets/glass_bottom_sheet.dart';

/// One row of [showActionSheet].
final class SheetAction {
  final String label;

  /// Runs once the sheet is closed, so it may open another route.
  final VoidCallback onPressed;

  final IconData? icon;

  /// Shown in the error colour (delete, remove).
  final bool destructive;

  /// The current choice among options (a sort order, a speed): accent
  /// colour and a check mark.
  final bool selected;

  const SheetAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.destructive = false,
    this.selected = false,
  });
}

/// The app's single action menu: a glass sheet above the mini player and
/// the tab bar, with an optional [title] and [message] over [actions]. A tap
/// closes it, then runs the action. Dismissed by a tap outside, a drag down
/// or back.
///
/// Long menus scroll, so a large font never overflows.
Future<void> showActionSheet(
  BuildContext context, {
  String? title,
  String? message,
  required List<SheetAction> actions,
}) => showGlassBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (sheetContext) => _ActionSheetBody(
    title: title,
    message: message,
    actions: actions,
    onSelected: (action) {
      Navigator.pop(sheetContext);
      AppHaptics.selectionClick();
      action.onPressed();
    },
  ),
);

/// Content of [showActionSheet].
class _ActionSheetBody extends StatelessWidget {
  final String? title;
  final String? message;
  final List<SheetAction> actions;
  final ValueChanged<SheetAction> onSelected;

  const _ActionSheetBody({
    this.title,
    this.message,
    required this.actions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final title = this.title;
    final message = this.message;
    final hasHeader = title != null || message != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.headlineSmall?.copyWith(
                          color: colors.labelPrimary,
                        ),
                      ),
                    ),
                  if (message != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        color: colors.labelSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (hasHeader) Divider(height: 1, color: colors.separator),
        if (hasHeader) const SizedBox(height: AppSpacing.xs),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final action in actions)
                  _ActionRow(action: action, onTap: () => onSelected(action)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final SheetAction action;
  final VoidCallback onTap;

  const _ActionRow({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = action.destructive
        ? Theme.of(context).colorScheme.error
        : action.selected
        ? colors.accent
        : colors.labelPrimary;
    final icon = action.icon;

    return Semantics(
      button: true,
      // Only options have a selected state; plain actions have none.
      selected: action.selected ? true : null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: color),
                    const SizedBox(width: AppSpacing.lg),
                  ],
                  Expanded(
                    child: Text(
                      action.label,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: action.selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (action.selected) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Icon(AppIcons.selected, size: 18, color: colors.accent),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
