import 'package:flutter/material.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';

/// A settings row choosing the accent: its title, then a round swatch per
/// accent, the chosen one marked with a check in its own text colour.
///
/// Swatches are 32 dp inside a 44 dp touch target, and wrap onto a second
/// line when the row is narrow or the font large.
class AccentPicker extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final AppAccent selected;
  final String Function(AppAccent accent) nameOf;
  final ValueChanged<AppAccent> onChanged;

  const AccentPicker({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    this.subtitle,
    required this.selected,
    required this.nameOf,
    required this.onChanged,
  });

  static const swatchSize = 32.0;
  static const touchSize = 44.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.labelSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            children: [
              for (final accent in AppAccent.values)
                _Swatch(
                  accent: accent,
                  name: nameOf(accent),
                  chosen: accent == selected,
                  onTap: () {
                    if (accent == selected) return;
                    AppHaptics.selectionClick();
                    onChanged(accent);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final AppAccent accent;
  final String name;
  final bool chosen;
  final VoidCallback onTap;

  const _Swatch({
    required this.accent,
    required this.name,
    required this.chosen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (color, foreground) = AppColors.accentOf(accent);
    return Semantics(
      button: true,
      selected: chosen,
      inMutuallyExclusiveGroup: true,
      label: name,
      // The ink's own tap is excluded with its semantics: the swatch's
      // node carries it, or a screen reader could not pick a colour.
      onTap: onTap,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        // The tick is AppHaptics' alone.
        enableFeedback: false,
        radius: AccentPicker.touchSize / 2,
        child: SizedBox.square(
          dimension: AccentPicker.touchSize,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: AccentPicker.swatchSize,
              height: AccentPicker.swatchSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                // The chosen one is ringed in white, away from its edge,
                // so the mark reads whatever the colour.
                border: Border.all(
                  color: chosen ? Colors.white : Colors.transparent,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              child: chosen
                  ? Icon(AppIcons.accentChosen, color: foreground, size: 18)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
