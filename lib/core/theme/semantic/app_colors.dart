import 'package:flutter/material.dart';
import 'package:troona/core/theme/primitives/color_primitives.dart';

@immutable
final class AppColors extends ThemeExtension<AppColors> {
  // ── Backgrounds ──────────────────────────────────────────
  final Color bgPrimary; // fond de page
  final Color bgSecondary; // surfaces élevées (cards, sheets)
  final Color bgTertiary; // surfaces encore plus élevées
  final Color bgElevated; // alertes, menus flottants

  // ── Labels ───────────────────────────────────────────────
  final Color labelPrimary;
  final Color labelSecondary;
  final Color labelTertiary;
  final Color labelQuaternary;

  // ── Séparateurs ──────────────────────────────────────────
  final Color separator;
  final Color separatorOpaque;

  // ── Accent ───────────────────────────────────────────────
  final Color accent; // rouge Apple Music
  final Color accentForeground; // texte sur fond accent

  // ── Glass ────────────────────────────────────────────────
  final Color glassFill; // fond du verre
  final Color glassBorder; // bordure supérieure lumineuse
  final Color glassHighlight; // reflet diagonal

  // ── Vibrancy ─────────────────────────────────────────────
  final Color vibrancyLabel;
  final Color vibrancySecondary;

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
    required this.separatorOpaque,
    required this.accent,
    required this.accentForeground,
    required this.glassFill,
    required this.glassBorder,
    required this.glassHighlight,
    required this.vibrancyLabel,
    required this.vibrancySecondary,
  });

  // ── Instances statiques ──────────────────────────────────

  static const light = AppColors(
    bgPrimary: ColorPrimitives.bgPrimaryLight,
    bgSecondary: ColorPrimitives.bgSecondaryLight,
    bgTertiary: ColorPrimitives.bgTertiaryLight,
    bgElevated: ColorPrimitives.bgElevatedLight,
    labelPrimary: ColorPrimitives.labelPrimaryLight,
    labelSecondary: ColorPrimitives.labelSecondaryLight,
    labelTertiary: ColorPrimitives.labelTertiaryLight,
    labelQuaternary: ColorPrimitives.labelQuaternaryLight,
    separator: ColorPrimitives.separatorLight,
    separatorOpaque: ColorPrimitives.separatorOpaqueLight,
    accent: ColorPrimitives.accent,
    accentForeground: ColorPrimitives.white,
    glassFill: ColorPrimitives.glassFillLight,
    glassBorder: ColorPrimitives.glassBorderLight,
    glassHighlight: ColorPrimitives.glassHighlightLight,
    vibrancyLabel: ColorPrimitives.vibrancyLabelLight,
    vibrancySecondary: ColorPrimitives.vibrancySecondaryLight,
  );

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
    separatorOpaque: ColorPrimitives.separatorOpaqueDark,
    accent: ColorPrimitives.accent,
    accentForeground: ColorPrimitives.white,
    glassFill: ColorPrimitives.glassFillDark,
    glassBorder: ColorPrimitives.glassBorderDark,
    glassHighlight: ColorPrimitives.glassHighlightDark,
    vibrancyLabel: ColorPrimitives.vibrancyLabelDark,
    vibrancySecondary: ColorPrimitives.vibrancySecondaryDark,
  );

  // ── ThemeExtension (pour lerp lors des transitions) ──────

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
    Color? separatorOpaque,
    Color? accent,
    Color? accentForeground,
    Color? glassFill,
    Color? glassBorder,
    Color? glassHighlight,
    Color? vibrancyLabel,
    Color? vibrancySecondary,
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
    separatorOpaque: separatorOpaque ?? this.separatorOpaque,
    accent: accent ?? this.accent,
    accentForeground: accentForeground ?? this.accentForeground,
    glassFill: glassFill ?? this.glassFill,
    glassBorder: glassBorder ?? this.glassBorder,
    glassHighlight: glassHighlight ?? this.glassHighlight,
    vibrancyLabel: vibrancyLabel ?? this.vibrancyLabel,
    vibrancySecondary: vibrancySecondary ?? this.vibrancySecondary,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      bgPrimary: Color.lerp(bgPrimary, other.bgPrimary, t)!,
      labelPrimary: Color.lerp(labelPrimary, other.labelPrimary, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      bgSecondary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      bgTertiary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      bgElevated: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      labelSecondary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      labelTertiary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      labelQuaternary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      separator: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      separatorOpaque: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      accent: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      accentForeground: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      glassHighlight: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      vibrancyLabel: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      vibrancySecondary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
    );
  }
}

// Extension de contexte — accès propre dans les widgets
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
