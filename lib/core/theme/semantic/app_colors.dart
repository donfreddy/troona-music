import 'package:flutter/material.dart';
import 'package:troona/core/theme/primitives/color_primitives.dart';

@immutable
final class AppColors extends ThemeExtension<AppColors> {
  // ── Backgrounds ──────────────────────────────────────────
  final Color bgPrimary; // page background
  final Color bgSecondary; // raised surfaces (cards, sheets)
  final Color bgTertiary; // surfaces raised further
  final Color bgElevated; // alerts, floating menus

  // ── Labels ───────────────────────────────────────────────
  final Color labelPrimary;
  final Color labelSecondary;
  final Color labelTertiary;
  final Color labelQuaternary;

  // ── Separators ──────────────────────────────────────────
  final Color separator;

  // ── Accent ───────────────────────────────────────────────
  final Color accent; // lilac
  final Color accentForeground; // text on the accent colour

  // ── Progress ─────────────────────────────────────────────
  final Color progressStart; // start of the arc (icy blue)
  final Color progressEnd; // head of the arc (white)

  // ── Quiet surfaces ───────────────────────────────────────
  // Not glass: glass surfaces take their colours from [GlassTheme], per
  // tier. These stay the same on every tier.
  final Color subtleFill; // a field, a placeholder behind an image
  final Color hairline; // the edge of an opaque surface (dialogs, rows)
  final Color pressedInk; // the ink of a pressed row

  const AppColors({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgTertiary,
    required this.bgElevated,
    required this.labelPrimary,
    required this.labelSecondary,
    required this.labelTertiary,
    required this.labelQuaternary,
    required this.separator,
    required this.accent,
    required this.accentForeground,
    required this.progressStart,
    required this.progressEnd,
    required this.subtleFill,
    required this.hairline,
    required this.pressedInk,
  });

  // ── The app's only theme: dark ─────────────────────────

  static const dark = AppColors(
    bgPrimary: ColorPrimitives.bgPrimaryDark,
    bgSecondary: ColorPrimitives.bgSecondaryDark,
    bgTertiary: ColorPrimitives.bgTertiaryDark,
    bgElevated: ColorPrimitives.bgElevatedDark,
    labelPrimary: ColorPrimitives.labelPrimaryDark,
    labelSecondary: ColorPrimitives.labelSecondaryDark,
    labelTertiary: ColorPrimitives.labelTertiaryDark,
    labelQuaternary: ColorPrimitives.labelQuaternaryDark,
    separator: ColorPrimitives.separatorDark,
    accent: ColorPrimitives.accent,
    accentForeground: ColorPrimitives.accentForeground,
    progressStart: ColorPrimitives.progressStart,
    progressEnd: ColorPrimitives.progressEnd,
    subtleFill: ColorPrimitives.subtleFillDark,
    hairline: ColorPrimitives.hairlineDark,
    pressedInk: ColorPrimitives.pressedInkDark,
  );

  // ── ThemeExtension (lerp during transitions) ──────

  @override
  AppColors copyWith({
    Color? bgPrimary,
    Color? bgSecondary,
    Color? bgTertiary,
    Color? bgElevated,
    Color? labelPrimary,
    Color? labelSecondary,
    Color? labelTertiary,
    Color? labelQuaternary,
    Color? separator,
    Color? accent,
    Color? accentForeground,
    Color? progressStart,
    Color? progressEnd,
    Color? subtleFill,
    Color? hairline,
    Color? pressedInk,
  }) => AppColors(
    bgPrimary: bgPrimary ?? this.bgPrimary,
    bgSecondary: bgSecondary ?? this.bgSecondary,
    bgTertiary: bgTertiary ?? this.bgTertiary,
    bgElevated: bgElevated ?? this.bgElevated,
    labelPrimary: labelPrimary ?? this.labelPrimary,
    labelSecondary: labelSecondary ?? this.labelSecondary,
    labelTertiary: labelTertiary ?? this.labelTertiary,
    labelQuaternary: labelQuaternary ?? this.labelQuaternary,
    separator: separator ?? this.separator,
    accent: accent ?? this.accent,
    accentForeground: accentForeground ?? this.accentForeground,
    progressStart: progressStart ?? this.progressStart,
    progressEnd: progressEnd ?? this.progressEnd,
    subtleFill: subtleFill ?? this.subtleFill,
    hairline: hairline ?? this.hairline,
    pressedInk: pressedInk ?? this.pressedInk,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      bgPrimary: Color.lerp(bgPrimary, other.bgPrimary, t)!,
      bgSecondary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      bgTertiary: Color.lerp(bgTertiary, other.bgTertiary, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      labelPrimary: Color.lerp(labelPrimary, other.labelPrimary, t)!,
      labelSecondary: Color.lerp(labelSecondary, other.labelSecondary, t)!,
      labelTertiary: Color.lerp(labelTertiary, other.labelTertiary, t)!,
      labelQuaternary: Color.lerp(labelQuaternary, other.labelQuaternary, t)!,
      separator: Color.lerp(separator, other.separator, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentForeground: Color.lerp(
        accentForeground,
        other.accentForeground,
        t,
      )!,
      progressStart: Color.lerp(progressStart, other.progressStart, t)!,
      progressEnd: Color.lerp(progressEnd, other.progressEnd, t)!,
      subtleFill: Color.lerp(subtleFill, other.subtleFill, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      pressedInk: Color.lerp(pressedInk, other.pressedInk, t)!,
    );
  }
}

// Context extension: clean access from widgets
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
