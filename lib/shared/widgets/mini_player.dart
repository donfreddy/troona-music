import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/pages/full_player_page.dart';

/// Compact now-playing bar shown above the bottom navigation bar.
///
/// Tapping anywhere opens [FullPlayerPage].  The play/pause and skip-next
/// buttons dispatch directly to [PlayerBloc] without navigating.
///
/// **Rendering contract** (same as [GlassCard]):
/// - Resolved from [GlassTheme.miniPlayer] — blur, fill, border, and radius
///   all come from the active [GlassQuality] preset.
/// - [BackdropFilter] is wrapped in [RepaintBoundary] to isolate its
///   compositing layer from position-stream rebuilds.
/// - When [GlassConfig.blurSigma] is 0 the fast path skips [BackdropFilter]
///   entirely.
///
/// **Rebuild strategy**: [BlocBuilder] is gated by [_miniKey] so the widget
/// only rebuilds when the track ID or play/pause state changes.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (p, c) => _miniKey(p) != _miniKey(c),
      builder: (context, state) {
        if (state is! PlayerActive) return const SizedBox.shrink();
        return _MiniPlayerBody(state: state);
      },
    );
  }

  (Object, bool) _miniKey(PlayerState s) => switch (s) {
    PlayerActive(:final currentTrack, :final isPlaying) => (
      currentTrack.id,
      isPlaying,
    ),
    _ => ('', false),
  };
}

// ─────────────────────────────────────────────────────────────────────────────

class _MiniPlayerBody extends StatelessWidget {
  final PlayerActive state;

  const _MiniPlayerBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final cfg = GlassTheme.miniPlayer(context);
    final colors = context.colors;

    final surface = _MiniPlayerSurface(
      config: cfg,
      colors: colors,
      state: state,
    );

    if (cfg.blurSigma == 0) {
      // Fast path: no BackdropFilter compositing layer.
      return ClipRRect(borderRadius: cfg.borderRadius, child: surface);
    }

    return GestureDetector(
      onTap: () => context.go(FullPlayerPage.routeName),
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: cfg.borderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: cfg.blurSigma,
              sigmaY: cfg.blurSigma,
              tileMode: TileMode.clamp,
            ),
            child: surface,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Decoration and content layout — kept separate so it sits inside the
/// [BackdropFilter] (the blur samples from what is painted behind this widget,
/// not from the decoration itself).
class _MiniPlayerSurface extends StatelessWidget {
  final GlassConfig config;
  final AppColors colors;
  final PlayerActive state;

  const _MiniPlayerSurface({
    required this.config,
    required this.colors,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: config.fill,
        borderRadius: config.borderRadius,
        border: Border.all(color: config.border, width: config.borderWidth),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),

          // ── Circular artwork thumbnail ──────────────────────────────────
          Hero(
            tag: 'artwork_${state.currentTrack.id}',
            child: SizedBox.square(
              dimension: 38,
              child: ClipOval(
                child: state.currentTrack.artworkPath != null
                    ? Image.file(
                        File(state.currentTrack.artworkPath!),
                        fit: BoxFit.cover,
                      )
                    : ColoredBox(
                        color: colors.glassFill,
                        child: Icon(
                          CupertinoIcons.music_note,
                          color: colors.labelTertiary,
                          size: 18,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ── Track title and artist ──────────────────────────────────────
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.currentTrack.title,
                  style: TextStyle(
                    color: colors.labelPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  state.currentTrack.artist,
                  style: TextStyle(
                    color: colors.labelSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ── Play / Pause ────────────────────────────────────────────────
          CupertinoButton(
            padding: const EdgeInsets.all(10),
            onPressed: () => context.read<PlayerBloc>().add(
              state.isPlaying
                  ? const PauseRequested()
                  : const ResumeRequested(),
            ),
            child: Icon(
              state.isPlaying
                  ? CupertinoIcons.pause_fill
                  : CupertinoIcons.play_fill,
              color: colors.labelPrimary,
              size: 20,
            ),
          ),

          // ── Skip next ───────────────────────────────────────────────────
          CupertinoButton(
            padding: const EdgeInsets.only(right: 12),
            onPressed: () =>
                context.read<PlayerBloc>().add(const SkipNextRequested()),
            child: Icon(
              CupertinoIcons.forward_fill,
              color: colors.labelPrimary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
