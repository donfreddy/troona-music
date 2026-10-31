import 'package:flutter/material.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/metadata/domain/entities/artist_online_info.dart';
import 'package:troona/shared/widgets/glass_card.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/shared/widgets/app_badge.dart';

class ArtistBioSection extends StatefulWidget {
  final ArtistOnlineInfo info;
  final void Function(String artistName)? onSimilarArtistTap;

  const ArtistBioSection({
    super.key,
    required this.info,
    this.onSimilarArtistTap,
  });

  @override
  State<ArtistBioSection> createState() => _ArtistBioSectionState();
}

class _ArtistBioSectionState extends State<ArtistBioSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bio = widget.info.bio;
    final listeners = _count(widget.info.listeners, context.l10n.metaListeners);
    final playCount = _count(widget.info.playCount, context.l10n.metaPlays);
    final tags = widget.info.tags;
    final similar = widget.info.similarArtists;
    final isOnTour = widget.info.isOnTour;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title & Last.fm badge & On-Tour badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.artistBio, size: 18, color: colors.accent),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      context.l10n.metaAboutArtist,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isOnTour) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                          border: Border.all(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.l10n.metaOnTour,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
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
                              color: Color(0xFFD51007), // Last.fm brand red
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
              ],
            ),

            // Tags (Genres, Styles, Vibe)
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

            // Stat chips
            if (listeners != null || playCount != null) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  if (listeners != null)
                    AppBadge(listeners, icon: AppIcons.listen),
                  if (playCount != null)
                    AppBadge(playCount, icon: AppIcons.play),
                ],
              ),
            ],

            // Bio content
            if (bio != null && bio.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                bio,
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
              if (bio.length > 200) ...[
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

            // Similar artists ("Artistes similaires")
            if (similar.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Icon(
                    AppIcons.similarArtists,
                    size: 14,
                    color: colors.labelSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.metaSimilarArtists,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.labelSecondary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: similar.map((sim) {
                  return InkWell(
                    onTap: widget.onSimilarArtistTap != null
                        ? () => widget.onSimilarArtistTap!(sim.name)
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (sim.imageUrl != null && sim.imageUrl!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ClipOval(
                                child: Image.network(
                                  sim.imageUrl!,
                                  width: 18,
                                  height: 18,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          Text(
                            sim.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
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
