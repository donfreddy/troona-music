import 'package:flutter/widgets.dart';

/// Turns off the heroes of [child] while its page comes in or goes, on
/// only once it is in: a page listing what the page below shows too
/// (Recent albums over Home's row) would otherwise fly every card they
/// share, from off screen for the ones built past its edge. Its heroes
/// still fly to and from a page pushed over it (an album's).
///
/// A pop gathers heroes a frame after it starts, once this has rebuilt.
/// A back swipe flies only heroes that ask to (`transitionOnUserGestures`),
/// which album covers do not. An album pushed while the page is still
/// coming in gets no flight in, yet flies back once the page is in.
class HeroesOnceIn extends StatefulWidget {
  final Widget child;

  const HeroesOnceIn({super.key, required this.child});

  @override
  State<HeroesOnceIn> createState() => _HeroesOnceInState();
}

class _HeroesOnceInState extends State<HeroesOnceIn> {
  ModalRoute<Object?>? _route;
  Animation<double>? _animation;
  bool _in = true;

  /// In: its animation done, and not put offstage, as a push does for a
  /// frame to measure where its heroes land (its animation then reads
  /// done too).
  bool get _isIn {
    final route = _route;
    return route == null ||
        (!route.offstage && (route.animation?.isCompleted ?? true));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    final animation = _route?.animation;
    if (animation != _animation) {
      _animation?.removeStatusListener(_onStatus);
      _animation = animation?..addStatusListener(_onStatus);
    }
    _in = _isIn;
  }

  void _onStatus(AnimationStatus _) {
    final isIn = _isIn;
    if (isIn != _in) setState(() => _in = isIn);
  }

  @override
  void dispose() {
    _animation?.removeStatusListener(_onStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      HeroMode(enabled: _in, child: widget.child);
}
