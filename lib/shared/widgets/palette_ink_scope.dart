import 'package:flutter/widgets.dart';
import 'package:troona/core/theme/primitives/color_primitives.dart';
import 'package:troona/core/theme/semantic/palette_ink.dart';
import 'package:troona/shared/widgets/dynamic_background.dart';

/// Hands the [PaletteInk] of the glow of [colorA] and [colorB] to the text
/// below, moving in step with a [DynamicBackground] fed the same colours
/// and [tone]: both run a [GlowCrossFade].
class PaletteInkScope extends StatefulWidget {
  final Color? colorA;
  final Color? colorB;
  final DynamicBackgroundTone tone;
  final Widget child;

  const PaletteInkScope({
    super.key,
    required this.colorA,
    required this.colorB,
    required this.tone,
    required this.child,
  });

  /// The ink of the app's ambient glow, outside any scope.
  static final fallback = PaletteInk.of(
    DynamicBackground.fitForText(ColorPrimitives.ambientTop),
    DynamicBackground.fitForText(ColorPrimitives.ambientEdge),
  );

  static PaletteInk of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Ink>()?.ink ?? fallback;

  @override
  State<PaletteInkScope> createState() => _PaletteInkScopeState();
}

class _PaletteInkScopeState extends State<PaletteInkScope>
    with SingleTickerProviderStateMixin {
  late final GlowCrossFade _glow = GlowCrossFade(
    vsync: this,
    colorA: widget.colorA,
    colorB: widget.colorB,
    tone: widget.tone,
  );

  (Color, Color)? _inkFor;
  PaletteInk? _ink;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _glow.follow(context, widget.tone);
  }

  @override
  void didUpdateWidget(PaletteInkScope old) {
    super.didUpdateWidget(old);
    _glow
      ..follow(context, widget.tone)
      ..moveTo(widget.colorA, widget.colorB);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  /// Worked out again only when the glow moved.
  PaletteInk get _current {
    final colors = _glow.colors;
    if (colors != _inkFor) {
      _inkFor = colors;
      _ink = PaletteInk.of(colors.$1, colors.$2);
    }
    return _ink!;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _glow.animation,
    child: widget.child,
    builder: (_, child) => _Ink(ink: _current, child: child!),
  );
}

class _Ink extends InheritedWidget {
  final PaletteInk ink;

  const _Ink({required this.ink, required super.child});

  @override
  bool updateShouldNotify(_Ink old) => ink != old.ink;
}
