import 'package:flutter/widgets.dart';

/// [child], or [alt] cross-faded over it while not null.
///
/// [child] stays mounted underneath (it keeps its state, a hero its tag)
/// and takes no touch nor screen reader focus while covered. An [alt] going
/// away fades out as it was last given. Both fill the same box.
class CrossFadeSwap extends StatefulWidget {
  final Widget? alt;
  final Widget child;

  const CrossFadeSwap({super.key, required this.alt, required this.child});

  static const duration = Duration(milliseconds: 200);

  @override
  State<CrossFadeSwap> createState() => _CrossFadeSwapState();
}

class _CrossFadeSwapState extends State<CrossFadeSwap> {
  /// The last [CrossFadeSwap.alt] shown, kept while it fades out.
  Widget? _shown;

  @override
  void initState() {
    super.initState();
    _shown = widget.alt;
  }

  @override
  void didUpdateWidget(CrossFadeSwap old) {
    super.didUpdateWidget(old);
    if (widget.alt != null) _shown = widget.alt;
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.alt != null;
    final shown = _shown;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        IgnorePointer(
          ignoring: on,
          child: ExcludeSemantics(
            excluding: on,
            child: AnimatedOpacity(
              opacity: on ? 0 : 1,
              duration: CrossFadeSwap.duration,
              child: widget.child,
            ),
          ),
        ),
        if (shown != null)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !on,
              child: ExcludeSemantics(
                excluding: !on,
                child: AnimatedOpacity(
                  opacity: on ? 1 : 0,
                  duration: CrossFadeSwap.duration,
                  onEnd: () {
                    if (!on && mounted) setState(() => _shown = null);
                  },
                  child: shown,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
