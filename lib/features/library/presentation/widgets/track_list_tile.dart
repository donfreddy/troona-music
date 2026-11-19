import 'package:flutter/material.dart';
import 'package:troona/shared/widgets/like_burst.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/widgets/queue_swipe.dart';
import 'package:troona/features/library/presentation/widgets/selection/selection_mark.dart';
import 'package:troona/features/library/presentation/widgets/selection/track_selection_scope.dart';
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

  /// A like from this row's menu pops a heart on it.
  final _burst = LikeBurstController();

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  // The menu ticks as it opens.
  void _showContextMenu(BuildContext context) {
    showTrackActions(
      context,
      widget.track,
      origin: TrackActionOrigin.library,
      onLikeToggled: (liked) => _burst.play(liked: liked),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (isActive, _) = TrackRowArtwork.statusOf(context, widget.track.id);

    final durationStr = Duration(
      milliseconds: widget.track.durationMs,
    ).toMMSS();

    final (picking, selected) = TrackSelectionScope.statusOf(
      context,
      widget.track.id,
    );

    return QueueSwipe(
      track: widget.track,
      enabled: !picking,
      // Its ink on a Material of its own: album and artist pages paint
      // their background over the Scaffold's, which would hide it. Tinted
      // while picked.
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: selected
            ? colors.accent.withValues(alpha: .12)
            : colors.accent.withValues(alpha: 0),
        child: Material(
          type: MaterialType.transparency,
          child: Semantics(
            selected: picking ? selected : null,
            child: InkWell(
              // The player ticks when the song starts. While its list picks,
              // a tap picks the song or lets it go.
              onTap: () {
                if (!TrackSelectionScope.tap(context, widget.track)) {
                  widget.onTap();
                }
              },
              onHighlightChanged: (value) => setState(() => _pressed = value),
              // In a list that can pick, a long press starts picking; the menu
              // stays on the row's options button.
              onLongPress:
                  widget.onLongPress ??
                  () {
                    if (!TrackSelectionScope.longPress(context, widget.track)) {
                      _showContextMenu(context);
                    }
                  },
              // Haptics are the app's (AppHaptics): the menu ticks as it opens, a
              // played song ticks in the player. The system's long-press buzz would
              // be a second one.
              enableFeedback: false,
              highlightColor: colors.pressedInk,
              splashColor: colors.pressedInk,
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
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          TrackRowArtwork(track: widget.track),
                          Positioned.fill(
                            child: SelectionMark(
                              picking: picking,
                              selected: selected,
                              radius: TrackRowArtwork.radius,
                            ),
                          ),
                          Positioned.fill(child: LikeBurst(controller: _burst)),
                        ],
                      ),

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
                                height: 1.2,
                              ),
                              // Lines of a set height, whatever fonts draw them
                              // (a title mixing Latin and CJK runs taller): the
                              // Library's list gives every row one height.
                              strutStyle: const StrutStyle(
                                fontSize: 15,
                                height: 1.2,
                                forceStrutHeight: true,
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
                                height: 1.2,
                              ),
                              strutStyle: const StrutStyle(
                                fontSize: 13,
                                height: 1.2,
                                forceStrutHeight: true,
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
                              : colors.labelSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),

                      const SizedBox(width: AppSpacing.sm),

                      // ── More options button ───────────────────────────────────────
                      // Gone while picking: the actions are the bar's. Its
                      // room is kept, so nothing moves.
                      IgnorePointer(
                        ignoring: picking,
                        child: AnimatedOpacity(
                          opacity: picking ? 0 : 1,
                          duration: const Duration(milliseconds: 200),
                          child: AppIconButton(
                            icon: AppIcons.more,
                            tooltip: context.l10n.detailMore,
                            size: 18,
                            color: context.colors.labelSecondary,
                            onPressed: () => _showContextMenu(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
