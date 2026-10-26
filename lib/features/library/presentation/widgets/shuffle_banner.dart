import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';

class ShuffleBanner extends StatelessWidget {
  final List<Track> tracks;

  const ShuffleBanner({super.key, required this.tracks});

  void _onShuffle(BuildContext context) {
    if (tracks.isEmpty) return;
    AppHaptics.mediumImpact();

    final bloc = context.read<PlayerBloc>();
    final alreadyShuffled = switch (bloc.state) {
      PlayerActive(:final shuffleEnabled) => shuffleEnabled,
      _ => false,
    };
    final shuffled = List<Track>.from(tracks)..shuffle();
    bloc.add(
      PlayTrackRequested(
        shuffled.first,
        contextQueue: shuffled,
        contextIndex: 0,
      ),
    );
    // A toggle: sending it while shuffle is on would turn it off.
    if (!alreadyShuffled) bloc.add(const ShuffleToggleRequested());
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
          InkWell(
            onTap: () => _onShuffle(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.accent.withValues(alpha: .3),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.shuffle, size: 14, color: colors.accent),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.actionShuffle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.accent,
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
