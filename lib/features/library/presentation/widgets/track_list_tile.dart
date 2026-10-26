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
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/shared/widgets/mini_equalizer.dart';

class TrackListTile extends StatefulWidget {
  final Track track;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const TrackListTile({
    super.key,
    required this.track,
    required this.onTap,
    this.onLongPress,
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
    final playerState = context.watch<PlayerBloc>().state;

    final isActive = playerState is PlayerActive &&
        playerState.currentTrack.id == widget.track.id;
    final isPlaying = isActive && playerState.isPlaying;

    final isLiked = context.select<LikesCubit, bool>(
      (c) => c.state.isTrackLiked(widget.track.id),
    );

    final durationStr =
        Duration(milliseconds: widget.track.durationMs).toMMSS();

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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 8,
          ),
          child: Row(
            children: [
              // ── Artwork with active MiniEqualizer overlay ──────────────────
              SizedBox.square(
                dimension: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: widget.track.artworkPath != null
                          ? ArtworkImage(
                              widget.track.artworkPath!,
                              width: 48,
                              height: 48,
                            )
                          : Container(
                              color: Colors.white.withValues(alpha: .08),
                              child: const Icon(
                                LucideIcons.music,
                                color: Colors.white30,
                                size: 22,
                              ),
                            ),
                    ),
                    if (isActive)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .55),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: MiniEqualizer(
                              isPlaying: isPlaying,
                              color: colors.accent,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
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
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.track.artist,
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

              const SizedBox(width: AppSpacing.xs),

              // ── Like button ───────────────────────────────────────────────
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  isLiked ? EvaIcons.heart : EvaIcons.heartOutline,
                  size: 19,
                  color: isLiked ? Colors.redAccent : Colors.white24,
                ),
                onPressed: () {
                  AppHaptics.selectionClick();
                  context.read<LikesCubit>().toggle(widget.track);
                },
              ),

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
