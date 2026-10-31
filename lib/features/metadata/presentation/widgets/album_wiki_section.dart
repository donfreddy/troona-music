import 'package:flutter/material.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/metadata/domain/entities/album_online_info.dart';
import 'package:troona/shared/widgets/glass_card.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/shared/widgets/app_badge.dart';

class AlbumWikiSection extends StatefulWidget {
  final AlbumOnlineInfo info;

  const AlbumWikiSection({super.key, required this.info});

  @override
  State<AlbumWikiSection> createState() => _AlbumWikiSectionState();
}

class _AlbumWikiSectionState extends State<AlbumWikiSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final wiki = widget.info.wiki;
    final published = widget.info.published;
    final listeners = _count(widget.info.listeners, context.l10n.metaListeners);
    final playCount = _count(widget.info.playCount, context.l10n.metaPlays);
    final tags = widget.info.tags;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title & Last.fm badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.album, size: 18, color: colors.accent),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      context.l10n.metaAboutAlbum,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD51007),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Last.fm',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.labelSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Tags (Genres, Styles)
            if (tags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.accent.withValues(alpha: 0.28),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.accent,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],

            // Stat chips & release info
            if (listeners != null ||
                playCount != null ||
                published != null) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  if (listeners != null)
                    AppBadge(listeners, icon: AppIcons.listen),
                  if (playCount != null)
                    AppBadge(playCount, icon: AppIcons.play),
                  if (published != null && published.isNotEmpty)
                    AppBadge(published, icon: AppIcons.releaseDate),
                ],
              ),
            ],

            // Wiki story content
            if (wiki != null && wiki.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                wiki,
                maxLines: _isExpanded ? null : 4,
                overflow: _isExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              if (wiki.length > 200) ...[
                const SizedBox(height: AppSpacing.xs),
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isExpanded
                              ? context.l10n.metaReadLess
                              : context.l10n.metaReadMore,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.accent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isExpanded ? AppIcons.collapse : AppIcons.expand,
                          size: 14,
                          color: colors.accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Last.fm sends counts as strings; unparsable ones are not shown.
String? _count(String? raw, String Function(int) label) {
  final count = int.tryParse(raw ?? '');
  return count == null ? null : label(count);
}
