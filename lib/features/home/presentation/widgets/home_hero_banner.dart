import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/features/player/domain/entities/queue_origin.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/utils/open_full_player.dart';
import 'package:troona/shared/widgets/meta_line.dart';
import 'package:troona/shared/widgets/mini_equalizer.dart';

/// Hero banner at the top of the home page.
///
/// Three modes:
/// - **Empty**: no music on the device; explains how to add some.
/// - **Fresh**: music but no plays yet; offers a shuffle of everything.
/// - **Continue**: the last played song, one tap to resume.
class HomeHeroBanner extends StatelessWidget {
  /// Null until something has been played.
  final Track? lastPlayed;
  final int totalTracks;
  final VoidCallback? onContinue;
  final VoidCallback? onShuffleAll;
  final VoidCallback? onScanAgain;

  const HomeHeroBanner({
    super.key,
    this.lastPlayed,
    required this.totalTracks,
    this.onContinue,
    this.onShuffleAll,
    this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: switch ((lastPlayed, totalTracks)) {
        (_, 0) => _buildWelcome(
          context,
          icon: AppIcons.track,
          title: l10n.homeEmptyTitle,
          body: l10n.homeEmptyBody,
          ctaIcon: AppIcons.refresh,
          ctaLabel: l10n.libraryScanAgain,
          onTap: onScanAgain,
        ),
        (null, _) => _buildWelcome(
          context,
          icon: AppIcons.listen,
          title: l10n.homeFreshTitle,
          body: l10n.homeSongsReady(totalTracks),
          ctaIcon: AppIcons.shuffle,
          ctaLabel: l10n.libraryShuffleAll,
          onTap: onShuffleAll,
        ),
        _ => _ResumeCard(lastPlayed: lastPlayed!, onReplay: onContinue),
      },
    );
  }

  // ── Empty and fresh: invitation card ────────────────────────────────────

  Widget _buildWelcome(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    required IconData ctaIcon,
    required String ctaLabel,
    required VoidCallback? onTap,
  }) {
    final glass = GlassTheme.card(context);
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.colors.accent.withValues(alpha: .15),
                context.colors.accent.withValues(alpha: .05),
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: glass.border, width: glass.borderWidth),
          ),
          child: Column(
            children: [
              // Music icon with subtle glow
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.accent.withValues(alpha: .12),
                ),
                child: Icon(icon, color: context.colors.accent, size: 28),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.labelPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.labelSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.accent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        ctaIcon,
                        color: context.colors.accentForeground,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        ctaLabel,
                        style: TextStyle(
                          color: context.colors.accentForeground,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }
}

/// The last session, one tap from going on: the current song of the
/// player's queue, where it was started from ("Album • Love, Damini") and
/// the listening time left in the queue, with a thin bar of how far it is.
/// Paused, a tap resumes it where it stopped; playing, it reads Now playing
/// and opens Now Playing.
///
/// Without a session (dismissed, or none yet), the last song played, which a
/// tap ([onReplay]) plays again from its start.
class _ResumeCard extends StatelessWidget {
  final Track lastPlayed;
  final VoidCallback? onReplay;

  const _ResumeCard({required this.lastPlayed, this.onReplay});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PlayerBloc>();
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (a, b) => _sessionOf(a) != _sessionOf(b),
      builder: (context, state) {
        final session = state is PlayerActive ? state : null;
        final l10n = context.l10n;
        final track = session?.currentTrack ?? lastPlayed;
        final playing = session?.isPlaying ?? false;
        return _card(
          context,
          track: track,
          label: playing ? l10n.homeNowPlaying : l10n.homeJumpBackIn,
          playing: playing,
          onTap: switch (session) {
            null => onReplay,
            _ when playing => () => openFullPlayer(
              context,
              fromMiniPlayer: false,
            ),
            _ => () => bloc.add(const ResumeRequested()),
          },
          origin: ValueListenableBuilder<QueueOrigin?>(
            valueListenable: bloc.origin,
            builder: (context, origin, _) => Text(
              switch (origin) {
                final origin? when session != null => MetaLine.join([
                  _kindOf(context, origin.kind),
                  origin.name,
                ])!,
                _ => context.artistName(track.artist),
              },
              style: TextStyle(
                color: context.colors.labelSecondary,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          progress: session == null
              ? null
              : ValueListenableBuilder<PlaybackProgress>(
                  valueListenable: bloc.progress,
                  builder: (context, progress, _) =>
                      _QueueTime(session: session, position: progress.position),
                ),
        );
      },
    );
  }

  /// What the card shows of a state: the song, whether it plays, the queue.
  static Object? _sessionOf(PlayerState state) => state is PlayerActive
      ? (state.currentTrack.id, state.isPlaying, state.queue)
      : null;

  static String _kindOf(BuildContext context, QueueOriginKind kind) =>
      switch (kind) {
        QueueOriginKind.album => context.l10n.queueOriginAlbum,
        QueueOriginKind.artist => context.l10n.queueOriginArtist,
        QueueOriginKind.playlist => context.l10n.queueOriginPlaylist,
      };

  Widget _card(
    BuildContext context, {
    required Track track,
    required String label,
    required bool playing,
    required VoidCallback? onTap,
    required Widget origin,
    required Widget? progress,
  }) {
    final glass = GlassTheme.card(context);
    final colors = context.colors;
    return Semantics(
      button: true,
      child:
          GestureDetector(
                onTap: onTap,
                child: Container(
                  width: double.infinity,
                  // At least the design height; taller when a large font needs it.
                  constraints: const BoxConstraints(minHeight: 100),
                  decoration: BoxDecoration(
                    color: glass.fill,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(
                      color: glass.border,
                      width: glass.borderWidth,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Background artwork, fading in from the left.
                      if (track.artworkPath != null)
                        Positioned.fill(
                          child: ShaderMask(
                            shaderCallback: (rect) => LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: .3),
                              ],
                            ).createShader(rect),
                            blendMode: BlendMode.dstIn,
                            child: ArtworkImage(
                              track.artworkPath!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                              child: SizedBox.square(
                                dimension: 68,
                                child: ArtworkImage(
                                  track.artworkPath,
                                  width: 68,
                                  height: 68,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      color: colors.accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    track.title,
                                    style: TextStyle(
                                      color: colors.labelPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  origin,
                                  ?progress,
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.accent,
                              ),
                              child: Center(
                                child: playing
                                    ? MiniEqualizer(
                                        color: colors.accentForeground,
                                        size: 16,
                                      )
                                    : Icon(
                                        AppIcons.play,
                                        color: colors.accentForeground,
                                        size: 20,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
    );
  }
}

/// The listening time left in the queue, and a thin bar of how far it is.
class _QueueTime extends StatelessWidget {
  final PlayerActive session;
  final Duration position;

  const _QueueTime({required this.session, required this.position});

  /// The queue's total length and how much of it has played.
  static (Duration total, Duration played) measure(
    PlayerActive session,
    Duration position,
  ) {
    final tracks = session.queue.playbackTracks;
    final index = session.queue.currentIndex.clamp(0, tracks.length - 1);
    var total = Duration.zero;
    var played = Duration.zero;
    for (final (i, t) in tracks.indexed) {
      final length = Duration(milliseconds: t.durationMs);
      total += length;
      if (i < index) played += length;
    }
    final current = Duration(milliseconds: tracks[index].durationMs);
    played += position > current ? current : position;
    return (total, played);
  }

  @override
  Widget build(BuildContext context) {
    final (total, played) = measure(session, position);
    final left = total - played;
    // Rounded up: "1 min" until the very end, never "0 min".
    final minutes = (left.inSeconds / 60).ceil().clamp(1, 1 << 31);
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.homeTimeLeft(
              Duration(minutes: minutes).toHumanReadable(context.l10n),
            ),
            style: TextStyle(color: colors.labelTertiary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: played.progressOf(total),
              minHeight: 3,
              color: colors.accent,
              backgroundColor: Colors.white.withValues(alpha: .12),
            ),
          ),
        ],
      ),
    );
  }
}
