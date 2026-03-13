import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/player_bloc.dart';
import 'package:troona/features/player/presentation/widgets/artwork_carousel.dart';
import 'package:troona/features/player/presentation/widgets/player_controls.dart';
import 'package:troona/features/player/presentation/widgets/queue_sheet.dart';
import 'package:troona/shared/widgets/app_bottom_nav_bar.dart';
import 'package:troona/shared/widgets/dynamic_background.dart';

class FullPlayerPage extends StatefulWidget {
  const FullPlayerPage({super.key});

  // Navigation via GoRouter — toujours un push depuis MiniPlayer
  static const routeName = '/player';

  @override
  State<FullPlayerPage> createState() => _FullPlayerPageState();
}

class _FullPlayerPageState extends State<FullPlayerPage> {
  // Quand l'user swipe le carousel manuellement, on joue le track visé
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
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<PlayerBloc, PlayerState>(
        builder: (context, state) {
          // Récupère les données nécessaires au build
          final track = switch (state) {
            PlayerActive(:final currentTrack) => currentTrack,
            PlayerLoading(:final track) => track,
            _ => null,
          };

          //final artworkPath = track?.artworkPath;

          return Stack(
            children: [
              // Fond dynamique
              DynamicBackground(
                artworkPath: track?.artworkPath,
                child: const SizedBox.expand(),
              ),

              // Contenu scrollable
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // ── Top bar : dismiss + options ────────────────
                    _TopBar(),

                    const SizedBox(height: AppSpacing.lg),

                    // ── Carousel artwork ───────────────────────────
                    if (state is PlayerActive)
                      ArtworkCarousel(
                        queue: state.queue.playbackTracks,
                        currentIndex: state.queue.currentIndex,
                        onPageChanged: _onCarouselPageChanged,
                      )
                    // ignore: dead_code
                    else if (track != null)
                      // // Loading : artwork seul sans carousel
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl3),
                      //   child: Hero(
                      //     tag: 'artwork_${track.id}',
                      //     child: AspectRatio(aspectRatio: 1, child: _ArtworkItem(track: track, isActive: true)),
                      //   ),
                      // ),
                      const SizedBox(height: AppSpacing.xl2),

                    // ── Titre + artiste + like ─────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl2,
                      ),
                      child: _TrackInfo(track: track),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Progress bar + contrôles ───────────────────
                    const PlayerControls(),

                    // const SizedBox(height: AppSpacing.xl2),

                    // // ── Volume slider ──────────────────────────────
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
                    //   child: const _VolumeSlider(),
                    // ),
                    const Spacer(),

                    // // ── Actions bas : lyrics · queue · airplay ─────
                    // const _BottomActions(),

                    // const SizedBox(height: AppSpacing.xl2),
                  ],
                ),
              ),

              // NavBar collée au bas — PAS de MiniPlayer
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, safeBottom + 12),
                  child: AppBottomNavBar(
                    currentTab: AppTab.player, // artwork tab actif
                    onTabChanged: (tab) {
                      Navigator.of(context).pop();
                      // puis navigate vers le tab
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────

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
          // Chevron bas — dismiss la page
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(
              CupertinoIcons.chevron_down,
              color: Colors.white,
              size: 22,
            ),
          ),

          // Pill indicateur (identique au design)
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Menu contextuel
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
              // TODO: ajouter à une playlist
            },
            child: const Text('Ajouter à une playlist'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: voir l'album
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

// ── Track info ────────────────────────────────────────────

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
        // Bouton like
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            // TODO: FavoriteBloc
          },
          child: const Icon(
            CupertinoIcons.heart,
            color: Colors.white70,
            size: 26,
          ),
        ),
      ],
    );
  }
}

// ── Volume slider ─────────────────────────────────────────

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
              value: 0.7, // TODO: brancher VolumeService
              onChanged: (_) {},
            ),
          ),
        ),
        const Icon(CupertinoIcons.volume_up, color: Colors.white38, size: 16),
      ],
    );
  }
}

// ── Bottom actions : lyrics · queue · airplay ─────────────

// ignore: unused_element
class _BottomActions extends StatelessWidget {
  const _BottomActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // _ActionButton(icon: CupertinoIcons.text_quote, label: 'Paroles', onTap: () => _showLyrics(context)),
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

  // void _showLyrics(BuildContext context) {
  //   showModalBottomSheet<void>(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (_) => BlocProvider.value(value: context.read<PlayerBloc>(), child: const LyricsSheet()),
  //   );
  // }

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
