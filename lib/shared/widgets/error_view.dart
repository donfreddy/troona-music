import 'package:flutter/cupertino.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/shared/widgets/app_button.dart';

/// Full-area error state. Shows user-facing copy only: raw failure messages
/// belong in the logs, not on screen.
class ErrorView extends StatelessWidget {
  final String? title;
  final String? body;
  final VoidCallback? onRetry;

  const ErrorView({super.key, this.title, this.body, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: 44, color: colors.labelTertiary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title ?? l10n.errorTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.labelPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body ?? l10n.errorGeneric,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.labelSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton.secondary(l10n.actionRetry, onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
