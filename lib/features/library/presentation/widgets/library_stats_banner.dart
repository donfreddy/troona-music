import 'package:flutter/material.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/layout/app_layout.dart';

class LibraryStatsBanner extends StatelessWidget {
  final int trackCount;
  final int albumCount;
  final int artistCount;

  const LibraryStatsBanner({
    super.key,
    required this.trackCount,
    required this.albumCount,
    required this.artistCount,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatItem(
        icon: AppIcons.track,
        value: '$trackCount',
        label: context.l10n.statSongs(trackCount),
      ),
      _StatItem(
        icon: AppIcons.album,
        value: '$albumCount',
        label: context.l10n.statAlbums(albumCount),
      ),
      _StatItem(
        icon: AppIcons.artist,
        value: '$artistCount',
        label: context.l10n.statArtists(artistCount),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: .06),
            width: 0.5,
          ),
        ),
        // Above the font size the row is laid out for, the counts wrap
        // instead of running off the banner.
        child:
            MediaQuery.textScalerOf(context).scale(1) > AppLayout.maxTextScale
            ? Wrap(
                alignment: WrapAlignment.spaceAround,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: stats,
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final (i, stat) in stats.indexed) ...[
                    if (i > 0) _Divider(),
                    stat,
                  ],
                ],
              ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.accent.withValues(alpha: .8)),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colors.labelSecondary),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 14,
      color: Colors.white.withValues(alpha: .1),
    );
  }
}
