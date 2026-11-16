import 'package:flutter/material.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/features/history/domain/services/play_intensity.dart';

/// One square of a recap grid, filled with the accent by [level] (0 to
/// [PlayIntensity.maxLevel]). Its look is shared by the calendar and "When
/// you listen", so a colour reads the same in both.
class HeatCell extends StatelessWidget {
  final int level;

  /// Written inside: the day of the month.
  final String? text;

  /// Ringed: today.
  final bool marked;

  /// Not lived yet: a day after today.
  final bool future;

  /// What a screen reader says, and what a tap shows.
  final String semanticLabel;

  const HeatCell({
    super.key,
    required this.level,
    required this.semanticLabel,
    this.text,
    this.marked = false,
    this.future = false,
  });

  static const _alphas = [0.0, .3, .52, .76, 1.0];

  /// The fill of [level]: glass when empty, then the accent, stronger.
  static Color fillOf(BuildContext context, int level, {bool future = false}) {
    if (level <= 0) {
      return Colors.white.withValues(alpha: future ? .025 : .06);
    }
    return context.colors.accent.withValues(alpha: _alphas[level]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = this.text;
    return Tooltip(
      message: semanticLabel,
      triggerMode: TooltipTriggerMode.tap,
      excludeFromSemantics: true,
      child: Semantics(
        label: semanticLabel,
        excludeSemantics: true,
        child: AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, box) => DecoratedBox(
              decoration: BoxDecoration(
                color: fillOf(context, level, future: future),
                borderRadius: BorderRadius.circular(box.maxWidth * .24),
                border: marked
                    ? Border.all(
                        color: Colors.white.withValues(alpha: .85),
                        width: 1.5,
                      )
                    : null,
              ),
              child: text == null
                  ? null
                  : Center(
                      child: FittedBox(
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Text(
                            text,
                            style: TextStyle(
                              color: level >= 3
                                  ? colors.accentForeground
                                  : future
                                  ? colors.labelQuaternary
                                  : colors.labelSecondary,
                              fontSize: 12,
                              fontWeight: level >= 3 || marked
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Less ▢▢▢▢▢ More": the steps of [HeatCell] from empty to full.
class HeatLegend extends StatelessWidget {
  const HeatLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final style = TextStyle(color: colors.labelTertiary, fontSize: 12);
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(l10n.recapLess, style: style),
          const SizedBox(width: 6),
          for (var level = 0; level <= PlayIntensity.maxLevel; level++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: HeatCell.fillOf(context, level),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          const SizedBox(width: 6),
          Text(l10n.recapMore, style: style),
        ],
      ),
    );
  }
}

/// Lights a grid's cells one diagonal after the other, from the top left,
/// when it first shows and each time [key] changes: a new span. Still when
/// animations are reduced.
class HeatCascade extends StatefulWidget {
  /// How many diagonals the grid has.
  final int steps;

  /// [reveal] wraps a cell on diagonal `step`.
  final Widget Function(
    BuildContext context,
    Widget Function(int step, Widget cell) reveal,
  )
  builder;

  const HeatCascade({super.key, required this.steps, required this.builder});

  static const _cell = Duration(milliseconds: 360);
  static const _stagger = Duration(milliseconds: 32);

  @override
  State<HeatCascade> createState() => _HeatCascadeState();
}

class _HeatCascadeState extends State<HeatCascade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: HeatCascade._cell + HeatCascade._stagger * widget.steps,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ctrl.isAnimating || _ctrl.value > 0) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _ctrl.value = 1;
    } else {
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _ctrl.duration!.inMicroseconds;
    final cell = HeatCascade._cell.inMicroseconds / total;
    final stagger = HeatCascade._stagger.inMicroseconds / total;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => widget.builder(context, (step, child) {
        if (_ctrl.value >= 1) return child;
        final t = ((_ctrl.value - step * stagger) / cell).clamp(0.0, 1.0);
        return Opacity(
          opacity: Curves.easeOut.transform(t),
          child: Transform.scale(
            scale: .6 + .4 * Curves.easeOutBack.transform(t),
            child: child,
          ),
        );
      }),
    );
  }
}
