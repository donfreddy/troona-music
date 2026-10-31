import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/utils/play_shuffled.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/shared/widgets/app_button.dart';

class ShuffleBanner extends StatelessWidget {
  final List<Track> tracks;

  const ShuffleBanner({super.key, required this.tracks});

  void _onShuffle(BuildContext context) {
    if (tracks.isEmpty) return;
    AppHaptics.mediumImpact();

    playShuffled(context.read<PlayerBloc>(), tracks);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (tracks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.l10n.songCount(tracks.length),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.labelSecondary,
            ),
          ),
          AppButton.secondary(
            context.l10n.actionShuffle,
            icon: AppIcons.shuffle,
            size: AppButtonSize.small,
            onPressed: () => _onShuffle(context),
          ),
        ],
      ),
    );
  }
}
