import 'package:flutter/material.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/widgets/queue_swipe.dart';
import 'package:troona/features/library/presentation/widgets/track_actions/show_track_actions.dart';
import 'package:troona/shared/widgets/app_icon_button.dart';
import 'package:troona/features/library/presentation/widgets/track_row_artwork.dart';

class TrackListTile extends StatefulWidget {
  final Track track;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// The line under the title: the artist, unless the page already names
  /// them (an artist's page gives the album instead).
  final String? subtitle;

  const TrackListTile({
    super.key,
    required this.track,
    required this.onTap,
    this.onLongPress,
    this.subtitle,
  });

  @override
  State<TrackListTile> createState() => _TrackListTileState();
}

class _TrackListTileState extends State<TrackListTile> {
  bool _pressed = false;

  void _showContextMenu(BuildContext context) {
    AppHaptics.lightImpact();
    showTrackActions(context, widget.track, origin: TrackActionOrigin.library);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (isActive, _) = TrackRowArtwork.statusOf(context, widget.track.id);

    final durationStr = Duration(
      milliseconds: widget.track.durationMs,
    ).toMMSS();

    return QueueSwipe(
      track: widget.track,
      child: InkWell(
        // The player ticks when the song starts.
        onTap: widget.onTap,
        onHighlightChanged: (value) => setState(() => _pressed = value),
        onLongPress: widget.onLongPress ?? () => _showContextMenu(context),
        highlightColor: colors.glassHighlight,
        splashColor: colors.glassHighlight,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                TrackRowArtwork(track: widget.track),

                const SizedBox(width: AppSpacing.md),

                // ── Track Title & Artist ──────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.track.title,
                        style: TextStyle(
                          color: isActive ? colors.accent : Colors.white,
                          fontSize: 15,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle ??
                            context.artistName(widget.track.artist),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .55),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                // ── Track Duration ────────────────────────────────────────────
                Text(
                  durationStr,
                  style: TextStyle(
                    color: isActive
                        ? colors.accent.withValues(alpha: 0.8)
                        : colors.labelTertiary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                // ── More options button ───────────────────────────────────────
                AppIconButton(
                  icon: AppIcons.more,
                  tooltip: context.l10n.detailMore,
                  size: 18,
                  color: context.colors.labelTertiary,
                  onPressed: () => _showContextMenu(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
