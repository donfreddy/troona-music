import 'package:flutter/material.dart';
import 'package:troona/shared/widgets/like_burst.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/app_icon_button.dart';
import 'package:troona/shared/widgets/mini_equalizer.dart';

/// Streamlined audiophile track row for album pages.
///
/// Displays:
/// - 2-digit track number (`01`, `02`) or animated [MiniEqualizer] when playing
/// - Track title (highlighted with accent color if active)
/// - Duration formatted as `mm:ss`
/// - Quick Like toggle and context menu
class AlbumTrackListTile extends StatefulWidget {
  final Track track;

  /// The number shown at the start of the row.
  final int number;

  /// Who the song is by, when the album's artist does not say it all.
  final String? subtitle;

  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const AlbumTrackListTile({
    super.key,
    required this.track,
    required this.number,
    this.subtitle,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<AlbumTrackListTile> createState() => _AlbumTrackListTileState();
}

class _AlbumTrackListTileState extends State<AlbumTrackListTile> {
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
      origin: TrackActionOrigin.album,
      onLikeToggled: (liked) => _burst.play(liked: liked),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Only the two flags this row draws: a watch on the whole state rebuilt
    // every visible row on each player emission (volume drag included).
    final (isActive, isPlaying) = context.select<PlayerBloc, (bool, bool)>((
      bloc,
    ) {
      final state = bloc.state;
      final active =
          state is PlayerActive && state.currentTrack.id == widget.track.id;
      return (active, active && state.isPlaying);
    });

    final trackNumStr = widget.number.toString().padLeft(2, '0');

    final durationStr = Duration(
      milliseconds: widget.track.durationMs,
    ).toMMSS();

    final (picking, selected) = TrackSelectionScope.statusOf(
      context,
      widget.track.id,
    );
    final hints = TrackSelectionScope.hintsOf(
      context,
      picking: picking,
      selected: selected,
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
            onTapHint: hints.tap,
            onLongPressHint: hints.longPress,
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
                      // ── Track number or animated MiniEqualizer ─────────────────────
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox.square(
                            dimension: 32,
                            child: AnimatedOpacity(
                              // The ring takes the number's place.
                              opacity: picking ? 0 : 1,
                              duration: const Duration(milliseconds: 200),
                              child: Center(
                                child: isActive
                                    ? MiniEqualizer(
                                        isPlaying: isPlaying,
                                        color: colors.accent,
                                        size: 14,
                                      )
                                    : Text(
                                        trackNumStr,
                                        style: TextStyle(
                                          color: colors.labelTertiary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: SelectionMark(
                              picking: picking,
                              selected: selected,
                              dim: false,
                            ),
                          ),
                          Positioned.fill(child: LikeBurst(controller: _burst)),
                        ],
                      ),

                      const SizedBox(width: AppSpacing.sm),

                      // ── Track Title ───────────────────────────────────────────────
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.track.title,
                              style: TextStyle(
                                color: isActive
                                    ? colors.accent
                                    : colors.labelPrimary,
                                fontSize: 15,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.subtitle case final subtitle?)
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: colors.labelSecondary,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(width: AppSpacing.sm),

                      // ── Track Duration (mm:ss) ────────────────────────────────────
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
