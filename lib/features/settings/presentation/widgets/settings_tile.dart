import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';

/// An iOS / Apple Settings style grouped list tile.
///
/// Features:
/// - Rounded square icon badge with vibrant background tint
/// - High-contrast title and secondary descriptive subtitle
/// - Trailing control (CupertinoSwitch, chevron, pill value, or custom widget)
/// - Subtle haptic feedback on interaction
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool enabled;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.enabled = true,
  });

  /// Factory helper for a boolean switch toggle with CupertinoSwitch.
  factory SettingsTile.switchTile({
    Key? key,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return SettingsTile(
      key: key,
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      enabled: enabled,
      onTap: enabled ? () => onChanged(!value) : null,
      trailing: CupertinoSwitch(
        value: value,
        activeTrackColor: iconColor,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  /// Factory helper for a navigation/modal row with a trailing chevron and optional value pill.
  factory SettingsTile.navigation({
    Key? key,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    String? value,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return SettingsTile(
      key: key,
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      enabled: enabled,
      onTap: onTap,
      showChevron: true,
      trailing: value != null
          ? Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white54,
                ),
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 11,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── 1. Rounded Square Icon Badge (Apple Settings Signature) ──────
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

          // ── 2. Title & Subtitle ───────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: enabled ? Colors.white : colors.labelTertiary,
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

          // ── 3. Trailing control & chevron ─────────────────────────────────
          ?trailing,
          if (showChevron) ...[
            const SizedBox(width: 4),
            Icon(AppIcons.disclosure, size: 18, color: colors.labelTertiary),
          ],
        ],
      ),
    );

    if (onTap == null || !enabled) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AppHaptics.lightImpact();
          onTap?.call();
        },
        child: content,
      ),
    );
  }
}
