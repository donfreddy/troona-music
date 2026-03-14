import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/widgets/artwork_carousel.dart';
import 'package:troona/features/player/presentation/widgets/player_controls.dart';
import 'package:troona/features/player/presentation/widgets/queue_sheet.dart';
import 'package:troona/shared/widgets/app_bottom_nav_bar.dart';
import 'package:troona/shared/widgets/dynamic_background.dart';

class FullPlayerPage extends StatefulWidget {
  const FullPlayerPage({super.key});

  static const routeName = '/player';

  @override
  State<FullPlayerPage> createState() => _FullPlayerPageState();
}

// ─────────────────────────────────────────────────────────────────────────────
// Drag-to-dismiss constants
// ─────────────────────────────────────────────────────────────────────────────

/// Minimum downward velocity (px/s) that triggers an instant dismiss.
const double _kDismissVelocity = 400;

/// Minimum drag distance (fraction of screen height) that triggers dismiss.
const double _kDismissThreshold = 0.25;

/// Maximum opacity reduction at the edge of the dismiss threshold.
const double _kMaxOpacityReduction = 0.35;

class _FullPlayerPageState extends State<FullPlayerPage>
    with SingleTickerProviderStateMixin {
  // ── Drag-to-dismiss state ─────────────────────────────────────────────────
  late final AnimationController _snapBack;
  late Animation<double> _snapAnim;
  double _dragOffset = 0;

  // ── Carousel / likes ──────────────────────────────────────────────────────
  void _onCarouselPageChanged(int index) {
    final state = context.read<PlayerBloc>().state;
    if (state is! PlayerActive) return;
    if (index == state.queue.currentIndex) return;
    context.read<PlayerBloc>().add(
      PlayTrackRequested(
        state.queue.playbackTracks[index],
        contextQueue: state.queue.playbackTracks,
        contextIndex: index,
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _snapAnim = const AlwaysStoppedAnimation(0);
    _snapBack = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(() {
        if (!mounted) return;
        setState(() => _dragOffset = _snapAnim.value);
      });

    final playerState = context.read<PlayerBloc>().state;
    if (playerState is PlayerActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<LikesCubit>().syncTrack(playerState.currentTrack);
      });
    }
  }

  @override
  void dispose() {
    _snapBack.dispose();
    super.dispose();
  }

  // ── Drag handlers ─────────────────────────────────────────────────────────

  void _onDragUpdate(DragUpdateDetails d) {
    // Only track downward movement.
    final next = _dragOffset + d.delta.dy;
    if (next >= 0) setState(() => _dragOffset = next);
  }

  void _onDragEnd(DragEndDetails d) {
    final velocity = d.velocity.pixelsPerSecond.dy;
    final screenH = MediaQuery.of(context).size.height;

    if (velocity > _kDismissVelocity || _dragOffset > screenH * _kDismissThreshold) {
      // Reset the manual translate so the Hero widget is back at its natural
      // screen position before the fade-out route transition starts. Without
      // this reset, the Hero would fly from the dragged (offset) position
      // instead of from the centre of the artwork carousel.
      setState(() => _dragOffset = 0);
      Navigator.of(context).pop();
    } else {
      // Snap back to fully-open position.
      _snapAnim = Tween<double>(begin: _dragOffset, end: 0).animate(
        CurvedAnimation(parent: _snapBack, curve: Curves.easeOutCubic),
      );
      _snapBack
        ..reset()
        ..forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final screenH = MediaQuery.of(context).size.height;

    // Fade the page out slightly as the user drags down.
    final opacity = 1.0 - (_dragOffset / screenH).clamp(0.0, _kMaxOpacityReduction);

    return GestureDetector(
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: Opacity(
          opacity: opacity,
          child: BlocListener<PlayerBloc, PlayerState>(
            listenWhen: (prev, curr) =>
                curr is PlayerActive &&
                (prev is! PlayerActive || prev.currentTrack != curr.currentTrack),
            listener: (context, state) {
              if (state is PlayerActive) {
                context.read<LikesCubit>().syncTrack(state.currentTrack);
              }
            },
            child: Scaffold(
              backgroundColor: Colors.black,
              body: BlocBuilder<PlayerBloc, PlayerState>(
                builder: (context, state) {
                  final track = switch (state) {
                    PlayerActive(:final currentTrack) => currentTrack,
                    PlayerLoading(:final track) => track,
                    _ => null,
                  };

                  return Stack(
                    children: [
                      // Dynamic background
                      DynamicBackground(
                        artworkPath: track?.artworkPath,
                        child: const SizedBox.expand(),
                      ),

                      // Scrollable content
                      SafeArea(
                        bottom: false,
                        child: Column(
                          children: [
                            // Top bar: dismiss + drag indicator + options
                            _TopBar(),

                            const SizedBox(height: AppSpacing.lg),

                            // Track info + like
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl2,
                              ),
                              child: _TrackInfo(track: track),
                            ),

                            const SizedBox(height: AppSpacing.lg),

                            // Artwork carousel
                            if (state is PlayerActive)
                              ArtworkCarousel(
                                queue: state.queue.playbackTracks,
                                currentIndex: state.queue.currentIndex,
                                onPageChanged: _onCarouselPageChanged,
                              )
                            // ignore: dead_code
                            else if (track != null)
                              const SizedBox(height: AppSpacing.xl2),

                            // Playback controls
                            const PlayerControls(),

                            const SizedBox(height: AppSpacing.xl2),
                          ],
                        ),
                      ),

                      // Nav bar at bottom — mini player hidden
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(12, 0, 12, safeBottom + 12),
                          child: AppBottomNavBar(
                            currentTab: AppTab.player,
                            showMiniPlayer: false,
                            onTabChanged: (_) => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(
              CupertinoIcons.chevron_down,
              color: Colors.white,
              size: 22,
            ),
          ),

          // Drag indicator pill
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showOptionsSheet(context),
            child: const Icon(
              CupertinoIcons.ellipsis_vertical,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    final state = context.read<PlayerBloc>().state;
    if (state is! PlayerActive) return;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              context.read<LikesCubit>().toggle(state.currentTrack);
            },
            child: const Text('Ajouter à Likes'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Voir l\'album'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TrackInfo extends StatelessWidget {
  final Track? track;
  const _TrackInfo({required this.track});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track?.title ?? '—',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                track?.artist ?? '—',
                style: const TextStyle(color: Colors.white60, fontSize: 16),
              ),
            ],
          ),
        ),
        BlocBuilder<LikesCubit, LikesState>(
          builder: (context, state) {
            final isLiked = state.isLiked && state.id == track?.id;
            return CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.read<LikesCubit>().toggle(track),
              child: Icon(
                isLiked ? CupertinoIcons.heart_solid : CupertinoIcons.heart,
                color: isLiked ? Colors.redAccent : Colors.white70,
                size: 26,
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

// ignore: unused_element
class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(CupertinoIcons.volume_mute, color: Colors.white38, size: 16),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: Colors.white60,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: 0.7,
              onChanged: (_) {},
            ),
          ),
        ),
        const Icon(CupertinoIcons.volume_up, color: Colors.white38, size: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

// ignore: unused_element
class _BottomActions extends StatelessWidget {
  const _BottomActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: CupertinoIcons.list_bullet,
          label: 'File',
          onTap: () => _showQueue(context),
        ),
        _ActionButton(
          icon: CupertinoIcons.play,
          label: 'AirPlay',
          onTap: () {},
        ),
      ],
    );
  }

  void _showQueue(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<PlayerBloc>(),
        child: const QueueSheet(),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white60, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
