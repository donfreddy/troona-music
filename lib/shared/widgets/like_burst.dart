import 'package:flutter/material.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';

/// Plays a [LikeBurst]: each [play] pops the heart once.
class LikeBurstController extends ValueNotifier<({int serial, bool liked})> {
  LikeBurstController() : super((serial: 0, liked: true));

  /// Pops a heart for a like, or a broken one for a like taken back.
  void play({required bool liked}) =>
      value = (serial: value.serial + 1, liked: liked);
}

/// The one answer to a like, wherever it is made: a heart that pops over
/// what was liked and fades (the mini player's cover, Now Playing's heart,
/// a song's row), or a broken heart for one taken back. Nothing with
/// reduced motion: the heart's own state or a toast says it.
class LikeBurst extends StatefulWidget {
  final LikeBurstController controller;

  /// The heart's size at rest.
  final double size;

  const LikeBurst({super.key, required this.controller, this.size = 28});

  @override
  State<LikeBurst> createState() => _LikeBurstState();
}

class _LikeBurstState extends State<LikeBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  static final _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: .3,
        end: 1.25,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.25,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 25,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
  ]);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_play);
  }

  @override
  void didUpdateWidget(LikeBurst old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_play);
      widget.controller.addListener(_play);
    }
  }

  void _play() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_play);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          if (t == 0 || t == 1) return const SizedBox.shrink();
          final liked = widget.controller.value.liked;
          return Opacity(
            opacity: t < .6 ? 1 : 1 - (t - .6) / .4,
            child: Transform.scale(
              scale: _scale.transform(t),
              child: Center(
                child: Icon(
                  key: const ValueKey('likeBurst'),
                  liked ? AppIcons.liked : AppIcons.unlike,
                  size: widget.size,
                  color: liked ? colors.accent : Colors.white,
                  shadows: const [
                    Shadow(color: Color(0x99000000), blurRadius: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
