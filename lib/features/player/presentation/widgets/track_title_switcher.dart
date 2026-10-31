import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_typography.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/shared/widgets/marquee.dart';

const Duration kTrackTitleSwapDuration = Duration(milliseconds: 280);

/// Whether going from queue position [from] to [to] reads as a next track.
///
/// Stepping from the last track to the first (repeat all) is a next, and
/// the reverse a previous; with two tracks that is ambiguous, so plain
/// order wins. Unknown positions count as a next.
@visibleForTesting
bool isNextTrack(int? from, int? to, int queueLength) {
  if (from == null || to == null) return true;
  if (queueLength > 2) {
    if (from == queueLength - 1 && to == 0) return true;
    if (from == 0 && to == queueLength - 1) return false;
  }
  return to >= from;
}

/// Title and artist of the current track. On a track change the old one
/// leaves and the new one arrives: upwards for a next track, downwards for
/// a previous one, fading out at the top and bottom edges instead of being
/// cut.
class TrackTitleSwitcher extends StatefulWidget {
  final Track? track;

  /// Position of [track] in the queue, to tell a next from a previous.
  final int? index;
  final int queueLength;

  const TrackTitleSwitcher({
    super.key,
    required this.track,
    required this.index,
    required this.queueLength,
  });

  @override
  State<TrackTitleSwitcher> createState() => _TrackTitleSwitcherState();
}

class _TrackTitleSwitcherState extends State<TrackTitleSwitcher>
    with SingleTickerProviderStateMixin {
  /// Bumped on every track change. Keying the switcher by track id would
  /// collide on a fast A, B, A skip while A is still leaving.
  int _swap = 0;

  /// Direction of the latest change; see [_SwapDirection].
  bool _next = true;

  /// Runs alongside each swap: the edge fades only show while titles move,
  /// so that at rest no ascender or descender is dimmed.
  late final _fade = AnimationController(
    vsync: this,
    duration: kTrackTitleSwapDuration,
  );

  /// Keeps the titles' state (switcher, marquee) when the fade mask is put
  /// around them or taken away.
  final _contentKey = GlobalKey();

  static const double _fadeHeight = 10;

  @override
  void didUpdateWidget(TrackTitleSwitcher old) {
    super.didUpdateWidget(old);
    if (old.track?.id == widget.track?.id) return;
    _next = isNextTrack(old.index, widget.index, widget.queueLength);
    _swap++;
    _fade.forward(from: 0);
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  /// Static on purpose: a new closure on every build would make
  /// [AnimatedSwitcher] rebuild all running transitions.
  static Widget _transition(Widget child, Animation<double> animation) =>
      _TitleTransition(animation: animation, child: child);

  /// Mask strength over a swap: eased in and out, so that the fade never
  /// pops on a title at rest.
  double get _fadeStrength {
    if (!_fade.isAnimating) return 0;
    final t = _fade.value;
    return math.min(t / 0.15, (1 - t) / 0.2).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    final content = KeyedSubtree(
      key: _contentKey,
      child: ClipRect(
        child: _SwapDirection(
          next: _next,
          child: AnimatedSwitcher(
            duration: kTrackTitleSwapDuration,
            transitionBuilder: _transition,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.centerLeft,
              children: [...previous, ?current],
            ),
            child: Column(
              key: ValueKey(_swap),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Marquee(
                  text: track?.title ?? '',
                  style: AppTypography.nowPlayingTitle.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  track == null ? '' : context.artistName(track.artist),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.nowPlayingArtist.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _fade,
      child: content,
      builder: (_, content) {
        final strength = _fadeStrength;
        if (strength == 0) return content!;
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) {
            final edge = math.min(_fadeHeight, bounds.height / 4);
            final stop = bounds.height > 0 ? edge / bounds.height : 0.0;
            final faded = Colors.black.withValues(alpha: 1 - strength);
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [faded, Colors.black, Colors.black, faded],
              stops: [0, stop, 1 - stop, 1],
            ).createShader(bounds);
          },
          child: content,
        );
      },
    );
  }
}

/// Direction of the latest track change, read by each title transition.
class _SwapDirection extends InheritedWidget {
  final bool next;

  const _SwapDirection({required this.next, required super.child});

  static bool read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_SwapDirection>()?.next ?? true;

  @override
  bool updateShouldNotify(_SwapDirection old) => false;
}

/// Slides one title in or out. Arriving, it follows the change that brought
/// it; leaving, the change that replaced it, latched when it starts to
/// leave: a quick next then previous never turns a title around mid-flight.
class _TitleTransition extends StatefulWidget {
  final Animation<double> animation;
  final Widget child;

  const _TitleTransition({required this.animation, required this.child});

  @override
  State<_TitleTransition> createState() => _TitleTransitionState();
}

class _TitleTransitionState extends State<_TitleTransition> {
  /// Latched once mounted, before any later change.
  bool? _arrivedOnNext;
  bool? _leavesOnNext;

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_onStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _arrivedOnNext ??= _SwapDirection.read(context);
  }

  @override
  void didUpdateWidget(_TitleTransition old) {
    super.didUpdateWidget(old);
    if (old.animation != widget.animation) {
      old.animation.removeStatusListener(_onStatus);
      widget.animation.addStatusListener(_onStatus);
    }
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onStatus);
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.reverse) {
      _leavesOnNext ??= _SwapDirection.read(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final animation = widget.animation;
    return AnimatedBuilder(
      animation: animation,
      child: widget.child,
      builder: (_, child) {
        final leaving = animation.status == AnimationStatus.reverse;
        final t = leaving
            ? Curves.easeInCubic.transform(animation.value)
            : const Interval(
                0.35,
                1,
                curve: Curves.easeOutCubic,
              ).transform(animation.value);
        // On a next, titles travel upwards: the old one leaves through the
        // top, the new one rises from below. On a previous, downwards.
        final upwards = (leaving ? _leavesOnNext : _arrivedOnNext) ?? true;
        final from = (leaving ? -0.6 : 0.6) * (upwards ? 1 : -1);
        return FractionalTranslation(
          translation: Offset(0, (1 - t) * from),
          child: Opacity(opacity: t, child: child),
        );
      },
    );
  }
}
