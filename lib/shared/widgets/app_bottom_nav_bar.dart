import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/player_bloc.dart';
import 'package:troona/features/player/presentation/widgets/rotating_artwork.dart';

enum AppTab {
  home,
  queue,
  player, // artwork central — pas un vrai tab, ouvre FullPlayer
  search,
  visualizer,
}

class AppBottomNavBar extends StatelessWidget {
  final AppTab currentTab;
  final ValueChanged<AppTab> onTabChanged;

  const AppBottomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      // Rebuild uniquement si track change ou play/pause change
      buildWhen: (p, c) => _navKey(p) != _navKey(c),
      builder: (context, playerState) {
        final track = playerState is PlayerActive
            ? playerState.currentTrack
            : null;
        final isPlaying = playerState is PlayerActive && playerState.isPlaying;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: _NavBarBody(
              currentTab: currentTab,
              onTabChanged: onTabChanged,
              track: track,
              isPlaying: isPlaying,
            ),
          ),
        );
      },
    );
  }

  (String?, bool) _navKey(PlayerState s) => switch (s) {
    PlayerActive(:final currentTrack, :final isPlaying) => (
      currentTrack.id,
      isPlaying,
    ),
    _ => (null, false),
  };
}

// ─────────────────────────────────────────────────────────

class _NavBarBody extends StatelessWidget {
  final AppTab currentTab;
  final ValueChanged<AppTab> onTabChanged;
  final Track? track;
  final bool isPlaying;

  const _NavBarBody({
    required this.currentTab,
    required this.onTabChanged,
    required this.track,
    required this.isPlaying,
  });

  static const _tabs = [
    (AppTab.home, CupertinoIcons.house_fill, 'Home'),
    (AppTab.queue, CupertinoIcons.list_bullet, 'Queue'),
    (AppTab.player, null, null), // artwork
    (AppTab.search, CupertinoIcons.search, 'Search'),
    (AppTab.visualizer, CupertinoIcons.waveform, 'Now'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl + 4),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .55),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl + 4),
            border: Border.all(
              color: Colors.white.withValues(alpha: .10),
              width: 0.5,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── 5 slots de navigation ─────────────────────
              Row(
                children: _tabs.map((tab) {
                  final (appTab, icon, label) = tab;

                  // Slot central — artwork
                  if (appTab == AppTab.player) {
                    // return Expanded(
                    //   child: _CenterArtworkSlot(
                    //     track: track,
                    //     isPlaying: isPlaying,
                    //     onTap: () => context.go(FullPlayerPage.routeName),
                    //   ),
                    // );
                  }

                  return Expanded(
                    child: _TabItem(
                      icon: icon!,
                      label: label!,
                      isActive: currentTab == appTab,
                      onTap: () => onTabChanged(appTab),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────

// ignore: unused_element
class _CenterArtworkSlot extends StatelessWidget {
  final Track? track;
  final bool isPlaying;
  final VoidCallback onTap;

  const _CenterArtworkSlot({
    required this.track,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox.expand(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Halo glow derrière l'artwork quand lecture en cours
            if (isPlaying)
              Positioned(
                top: -8,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: .45),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),

            // Artwork rotatif — surélevé de 12px au-dessus de la bar
            Positioned(
              top: -12,
              child: RotatingArtwork(
                track: track,
                isPlaying: isPlaying,
                size: 56,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox.expand(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isActive ? 1.0 : 0.4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
