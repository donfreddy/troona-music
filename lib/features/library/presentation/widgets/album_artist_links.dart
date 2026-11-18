import 'package:flutter/material.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist_credit.dart';
import 'package:troona/shared/widgets/action_sheet.dart';

/// The album's artists under its name, one line that opens their page. An
/// album by several asks which one, as Now Playing does: links side by
/// side would wrap over the header's facts and be too small to touch.
/// Songs by different artists, or none: no page to open.
class AlbumArtistLinks extends StatelessWidget {
  final Album album;

  const AlbumArtistLinks({super.key, required this.album});

  /// The touch target, whatever the line's height.
  static const double minHeight = 44;

  static const double _fontSize = 16;

  void _open(BuildContext context, List<ArtistCredit> credits) {
    AppHaptics.lightImpact();
    if (credits.length == 1) {
      context.pushArtist('${credits.single.id}');
      return;
    }
    showActionSheet(
      context,
      title: context.l10n.trackGoToArtist,
      actions: [
        for (final credit in credits)
          SheetAction(
            label: credit.name,
            icon: AppIcons.artist,
            onPressed: () => context.pushArtist('${credit.id}'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final credits = album.credits;
    if (credits.isEmpty) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minHeight),
        child: Center(
          widthFactor: 1,
          child: Text(
            context.artistName(album.artist),
            style: TextStyle(
              color: colors.labelSecondary,
              fontSize: _fontSize,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => _open(context, credits),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    credits.map((c) => c.name).join(', '),
                    style: TextStyle(
                      color: colors.accent,
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(AppIcons.disclosure, color: colors.accent, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
