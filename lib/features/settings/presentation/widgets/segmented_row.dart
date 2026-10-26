import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';

/// An Apple Settings style segmented selector tile.
class SegmentedRow<T extends Object> extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  const SegmentedRow({
    super.key,
    required this.label,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

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
          const SizedBox(height: AppSpacing.sm + 4),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<T>(
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              thumbColor: colors.accent,
              groupValue: selected,
              children: {
                for (var i = 0; i < values.length; i++)
                  values[i]: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected == values[i]
                            ? Colors.white
                            : colors.labelSecondary,
                      ),
                    ),
                  ),
              },
              onValueChanged: (val) {
                if (val != null) {
                  AppHaptics.selectionClick();
                  onChanged(val);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
