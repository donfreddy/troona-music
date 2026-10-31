import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/updates/domain/entities/app_release.dart';
import 'package:troona/features/updates/presentation/cubit/update_cubit.dart';
import 'package:troona/features/updates/presentation/open_release.dart';
import 'package:troona/shared/widgets/app_button.dart';

/// Home card announcing a newer release, until it is installed or skipped.
class UpdateCard extends StatelessWidget {
  const UpdateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UpdateCubit, UpdateState>(
      bloc: getIt<UpdateCubit>(),
      builder: (context, state) {
        final release = state.available;
        if (!state.showCard || release == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: _Card(release: release),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  final AppRelease release;

  const _Card({required this.release});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final glass = GlassTheme.card(context);
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: glass.fill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: glass.border, width: glass.borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.update, color: colors.accent, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.updateAvailable(release.version),
                  style: TextStyle(
                    color: colors.labelPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.updateAvailableBody,
            style: TextStyle(
              color: colors.labelSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton.text(
                l10n.updateSkip,
                onPressed: getIt<UpdateCubit>().skip,
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton.primary(
                l10n.updateView,
                onPressed: () => openRelease(context, release),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
