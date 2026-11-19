import 'package:flutter/material.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';

/// Laid over a song row's cover or number while its list picks: the cover
/// dims under a ring, filled with a check once the song is picked. Nothing
/// at rest.
class SelectionMark extends StatelessWidget {
  /// Whether the list is picking.
  final bool picking;
  final bool selected;

  /// Corner radius of the cover it dims.
  final double radius;

  /// Whether it dims what it covers: a cover, not a number (which the row
  /// fades out itself).
  final bool dim;

  const SelectionMark({
    super.key,
    required this.picking,
    required this.selected,
    this.radius = 0,
    this.dim = true,
  });

  static const double size = 24;
  static const _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: picking ? 1 : 0,
        duration: _duration,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: dim ? Colors.black.withValues(alpha: .45) : null,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Center(
            child: SizedBox.square(
              dimension: size,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.labelPrimary.withValues(alpha: .8),
                        width: 1.5,
                      ),
                    ),
                  ),
                  // A pick pops in; with reduced motion it fades.
                  AnimatedScale(
                    scale: selected || reduceMotion ? 1 : .4,
                    duration: _duration,
                    curve: selected ? Curves.easeOutBack : Curves.easeIn,
                    child: AnimatedOpacity(
                      opacity: selected ? 1 : 0,
                      duration: _duration,
                      child: DecoratedBox(
                        key: const ValueKey('selectionCheck'),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.accent,
                        ),
                        child: Icon(
                          AppIcons.selected,
                          size: 16,
                          color: colors.accentForeground,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
