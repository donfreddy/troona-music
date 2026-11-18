import 'package:flutter/material.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/library/domain/entities/album.dart';

/// The album's artists under its name, each opening their page: "A, B"
/// is two links. Songs by different artists, or none: no page to open.
class AlbumArtistLinks extends StatelessWidget {
  final Album album;

  const AlbumArtistLinks({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final credits = album.credits;
    const size = 16.0;
    if (credits.isEmpty) {
      return Text(
        context.artistName(album.artist),
        style: TextStyle(
          color: colors.labelSecondary,
          fontSize: size,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    final style = TextStyle(
      color: colors.accent,
      fontSize: size,
      fontWeight: FontWeight.w700,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (i, credit) in credits.indexed)
          InkWell(
            onTap: () {
              AppHaptics.lightImpact();
              context.pushArtist('${credit.id}');
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: credit.name),
                    if (i < credits.length - 1)
                      const TextSpan(text: ',')
                    else
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            AppIcons.disclosure,
                            color: colors.accent,
                            size: size,
                          ),
                        ),
                      ),
                  ],
                ),
                style: style,
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
