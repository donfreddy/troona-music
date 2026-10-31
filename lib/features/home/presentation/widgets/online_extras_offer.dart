import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/shared/widgets/app_toast.dart';
import 'package:troona/shared/widgets/app_button.dart';

/// One-time card asking whether to turn on the online extras (Last.fm and
/// Deezer). They are off by default; either answer hides the card for good.
class OnlineExtrasOffer extends StatelessWidget {
  const OnlineExtrasOffer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<SettingsCubit>(),
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          final offered = switch (state) {
            SettingsLoaded(:final settings) => settings.onlineExtrasOffered,
            _ => true,
          };
          if (offered) return const SizedBox.shrink();
          return const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: _OfferCard(),
          );
        },
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final glass = GlassTheme.card(context);
    final l10n = context.l10n;
    final cubit = context.read<SettingsCubit>();

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
              Icon(LucideIcons.micVocal, color: colors.accent, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.homeExtrasTitle,
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
            l10n.homeExtrasBody,
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
                l10n.homeExtrasDecline,
                onPressed: () {
                  cubit.dismissOnlineExtrasOffer();
                  AppToast.show(context, l10n.homeExtrasDeclined);
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton.primary(
                l10n.homeExtrasAccept,
                onPressed: () => cubit.setOnlineExtras(true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
