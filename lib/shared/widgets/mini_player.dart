import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/features/player/presentation/bloc/player_bloc.dart';
import 'package:troona/features/player/presentation/pages/full_player_page.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (p, c) => _miniKey(p) != _miniKey(c),
      builder: (context, state) {
        if (state is! PlayerActive) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => context.go(FullPlayerPage.routeName),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  // Fond sombre glassmorphism — identique screenshot
                  color: Colors.black.withValues(alpha: .72),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .10),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),

                    // ── Artwork rond ───────────────────────────
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
                              : Container(
                                  color: Colors.white12,
                                  child: const Icon(
                                    CupertinoIcons.music_note,
                                    color: Colors.white38,
                                    size: 18,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ── Titre + artiste ────────────────────────
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.currentTrack.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            state.currentTrack.artist,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Pause ──────────────────────────────────
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
                        color: Colors.white,
                        size: 20,
                      ),
                    ),

                    // ── Skip ───────────────────────────────────
                    CupertinoButton(
                      padding: const EdgeInsets.only(right: 12),
                      onPressed: () => context.read<PlayerBloc>().add(
                        const SkipNextRequested(),
                      ),
                      child: const Icon(
                        CupertinoIcons.forward_fill,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
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
