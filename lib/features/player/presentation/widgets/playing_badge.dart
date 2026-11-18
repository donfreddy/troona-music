import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/mini_equalizer.dart';

/// The small equalizer on an album or artist card while the current song
/// is theirs ([matches]), still while paused: the look of the current song
/// in lists, carried to the grids. Nothing otherwise.
class PlayingBadge extends StatelessWidget {
  /// Whether the current song belongs to the card.
  final bool Function(Track current) matches;

  const PlayingBadge({super.key, required this.matches});

  static const double size = 24;

  @override
  Widget build(BuildContext context) {
    // Two flags only: the whole state would rebuild every card on each
    // player emission.
    final (active, playing) = context.select<PlayerBloc, (bool, bool)>((bloc) {
      final state = bloc.state;
      final active = state is PlayerActive && matches(state.currentTrack);
      return (active, active && state.isPlaying);
    });
    if (!active) return const SizedBox.shrink();
    return Semantics(
      label: context.l10n.queueNowPlaying,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .6),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: MiniEqualizer(
          isPlaying: playing,
          color: context.colors.accent,
          size: 12,
        ),
      ),
    );
  }
}
