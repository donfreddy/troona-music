import 'package:flutter/material.dart';
import 'package:troona/core/utils/haptics_helper.dart';

/// Which way the finger moved.
enum SwipeDirection { left, right }

/// A horizontal swipe on [child] that runs an action once the finger has
/// gone past [threshold], then springs back: the row stays where it is.
///
/// A tick ([AppHaptics.selectionClick]) marks the threshold each time it is
/// crossed, so the finger knows the action is armed before it lets go. A
/// fast fling runs it too. A direction without an action resists the
/// finger instead of following it.
///
/// [background] paints under the child as it moves, given the direction,
/// how far along the threshold it is (0 to 1) and whether it is armed. It
/// holds no tap targets: taps go to [child], vertical drags to the list.
class SwipeActions extends StatefulWidget {
  final Widget child;

  /// The finger moved left (toward the start of the next song, the end of
  /// the queue).
  final VoidCallback? onSwipeLeft;

  /// The finger moved right.
  final VoidCallback? onSwipeRight;

  final double threshold;

  /// Fades [child] as it moves, for a swipe that replaces it (the mini
  /// player's song).
  final bool fadeChild;

  final Widget Function(
    BuildContext context,
    SwipeDirection direction,
    double progress,
    bool armed,
  )?
  background;

  const SwipeActions({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.threshold = 72,
    this.fadeChild = false,
    this.background,
  });

  /// Speed past which a swipe runs its action, however short.
  static const double flingVelocity = 700;

  @override
  State<SwipeActions> createState() => _SwipeActionsState();
}

class _SwipeActionsState extends State<SwipeActions>
    with SingleTickerProviderStateMixin {
  late final AnimationController _back = AnimationController.unbounded(
    vsync: this,
  )..addListener(() => setState(() => _offset = _back.value));

  double _offset = 0;
  bool _armed = false;

  VoidCallback? _actionFor(double offset) => offset < 0
      ? widget.onSwipeLeft
      : offset > 0
      ? widget.onSwipeRight
      : null;

  void _onUpdate(DragUpdateDetails details) {
    _back.stop();
    final delta = details.primaryDelta ?? 0;
    // Without an action that way, the finger meets resistance.
    final next = _offset + delta;
    final resisted = _actionFor(next) == null ? _offset + delta * .2 : next;
    final armed = resisted.abs() >= widget.threshold;
    if (armed != _armed) AppHaptics.selectionClick();
    setState(() {
      _offset = resisted;
      _armed = armed;
    });
  }

  void _onEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final flung =
        velocity.abs() >= SwipeActions.flingVelocity &&
        velocity.sign == _offset.sign;
    final action = _actionFor(_offset);
    if (action != null && (_armed || flung)) {
      if (!_armed) AppHaptics.selectionClick();
      action();
    }
    _armed = false;
    _back.value = _offset;
    _back.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offset = _offset;
    final background = widget.background;
    Widget child = Transform.translate(
      offset: Offset(offset, 0),
      child: widget.child,
    );
    if (widget.fadeChild) {
      child = Opacity(
        opacity: (1 - offset.abs() / (widget.threshold * 2.5)).clamp(.3, 1),
        child: child,
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: _onUpdate,
      onHorizontalDragEnd: _onEnd,
      onHorizontalDragCancel: () => _onEnd(DragEndDetails()),
      // One structure, moving or not: the child keeps its state (and a
      // hero in it) through a swipe.
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: background == null || offset == 0
                  ? const SizedBox.shrink()
                  : background(
                      context,
                      offset < 0 ? SwipeDirection.left : SwipeDirection.right,
                      (offset.abs() / widget.threshold).clamp(0, 1),
                      _armed,
                    ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
