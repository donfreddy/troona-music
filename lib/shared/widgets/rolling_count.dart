import 'package:flutter/material.dart';

/// A number whose digits roll when it changes: up when it grows, down when
/// it shrinks, each place on its own (10 to 11 rolls the units only; 9 to
/// 10 rolls the units while the new tens digit comes in place). With
/// reduced motion the digits change in place.
///
/// Drawn in tabular figures, so the width moves only when a place comes or
/// goes. Screen readers get the number from the caller's label.
class RollingCount extends StatefulWidget {
  final int value;
  final TextStyle? style;

  const RollingCount(this.value, {super.key, this.style});

  static const duration = Duration(milliseconds: 260);

  @override
  State<RollingCount> createState() => _RollingCountState();
}

class _RollingCountState extends State<RollingCount> {
  /// Whether the last change made the number grow.
  bool _up = true;

  @override
  void didUpdateWidget(RollingCount old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) _up = widget.value > old.value;
  }

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style
        .merge(widget.style)
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final digits = widget.value.abs().toString();
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: [
          if (widget.value < 0) Text('-', style: style),
          // Keyed by place from the right: a units digit stays the units
          // digit when a tens place comes.
          for (var i = 0; i < digits.length; i++)
            _RollingDigit(
              key: ValueKey(digits.length - 1 - i),
              digit: digits[i],
              up: _up,
              style: style,
            ),
        ],
      ),
    );
  }
}

class _RollingDigit extends StatefulWidget {
  final String digit;
  final bool up;
  final TextStyle style;

  const _RollingDigit({
    super.key,
    required this.digit,
    required this.up,
    required this.style,
  });

  @override
  State<_RollingDigit> createState() => _RollingDigitState();
}

class _RollingDigitState extends State<_RollingDigit>
    with SingleTickerProviderStateMixin {
  late final _roll = AnimationController(
    vsync: this,
    duration: RollingCount.duration,
    value: 1,
  );
  late final _curve = CurvedAnimation(
    parent: _roll,
    curve: Curves.easeOutCubic,
  );
  String? _previous;
  bool _up = true;

  @override
  void didUpdateWidget(_RollingDigit old) {
    super.didUpdateWidget(old);
    if (widget.digit == old.digit) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _previous = null;
      _roll.value = 1;
      return;
    }
    // Rolled again mid-roll: the digit leaving is the one showing.
    _previous = old.digit;
    _up = widget.up;
    _roll.forward(from: 0);
  }

  @override
  void dispose() {
    _curve.dispose();
    _roll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = Text(widget.digit, style: widget.style);
    return AnimatedBuilder(
      animation: _curve,
      child: current,
      builder: (context, child) {
        final t = _curve.value;
        final previous = _previous;
        if (t >= 1 || previous == null) return child!;
        // Up: the new digit comes from below, the old one leaves upwards.
        final sign = _up ? 1.0 : -1.0;
        return ClipRect(
          child: Stack(
            children: [
              FractionalTranslation(
                translation: Offset(0, -sign * t),
                child: Opacity(
                  opacity: 1 - t,
                  child: Text(previous, style: widget.style),
                ),
              ),
              FractionalTranslation(
                translation: Offset(0, sign * (1 - t)),
                child: Opacity(opacity: t, child: child),
              ),
            ],
          ),
        );
      },
    );
  }
}
