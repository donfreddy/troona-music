import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/widgets/track_actions/show_track_actions.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
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
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const AlbumTrackListTile({
    super.key,
    required this.track,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<AlbumTrackListTile> createState() => _AlbumTrackListTileState();
}

class _AlbumTrackListTileState extends State<AlbumTrackListTile> {
  bool _pressed = false;

  void _showContextMenu(BuildContext context) {
    AppHaptics.lightImpact();
    showTrackActions(context, widget.track, origin: TrackActionOrigin.album);
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

    final isLiked = context.select<LikesCubit, bool>(
      (c) => c.state.isTrackLiked(widget.track.id),
    );

    final trackNum = widget.track.trackNumber;
    final trackNumStr = trackNum != null && trackNum > 0
        ? trackNum.toString().padLeft(2, '0')
        : '-';

    final durationStr = Duration(
      milliseconds: widget.track.durationMs,
    ).toMMSS();

    return InkWell(
      onTap: () {
        AppHaptics.selectionClick();
        widget.onTap();
      },
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
              // ── Track number or animated MiniEqualizer ─────────────────────
              SizedBox.square(
                dimension: 32,
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
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // ── Track Title ───────────────────────────────────────────────
              Expanded(
                child: Text(
                  widget.track.title,
                  style: TextStyle(
                    color: isActive ? colors.accent : colors.labelPrimary,
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // ── Track Duration (mm:ss) ────────────────────────────────────
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
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 32),
                icon: const Icon(
                  LucideIcons.ellipsis,
                  size: 18,
                  color: Colors.white30,
                ),
                onPressed: () => _showContextMenu(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
