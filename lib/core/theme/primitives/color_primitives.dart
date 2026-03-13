import 'package:flutter/material.dart';

abstract final class ColorPrimitives {
  // ── Neutrals (iOS system grays) ─────────────────────────
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);

  // systemGray scale — identiques à iOS
  static const gray1 = Color(0xFF8E8E93);
  static const gray2 = Color(0xFFAEAEB2);
  static const gray3 = Color(0xFFC7C7CC);
  static const gray4 = Color(0xFFD1D1D6);
  static const gray5 = Color(0xFFE5E5EA);
  static const gray6 = Color(0xFFF2F2F7);

  // ── Backgrounds iOS ──────────────────────────────────────
  // Light
  static const bgPrimaryLight = Color(0xFFFFFFFF);
  static const bgSecondaryLight = Color(0xFFF2F2F7);
  static const bgTertiaryLight = Color(0xFFFFFFFF);
  static const bgElevatedLight = Color(0xFFFFFFFF);

  // Dark — CRITIQUE : Apple utilise 4 niveaux de gris très proches
  static const bgPrimaryDark = Color(0xFF000000);
  static const bgSecondaryDark = Color(0xFF1C1C1E);
  static const bgTertiaryDark = Color(0xFF2C2C2E);
  static const bgElevatedDark = Color(0xFF3A3A3C);

  // ── Text iOS ─────────────────────────────────────────────
  static const labelPrimaryLight = Color(0xFF000000);
  static const labelSecondaryLight = Color(0x993C3C43); // 60% opacité
  static const labelTertiaryLight = Color(0x4D3C3C43); // 30%
  static const labelQuaternaryLight = Color(0x2E3C3C43); // 18%

  static const labelPrimaryDark = Color(0xFFFFFFFF);
  static const labelSecondaryDark = Color(0x99EBEBF5);
  static const labelTertiaryDark = Color(0x4DEBEBF5);
  static const labelQuaternaryDark = Color(0x29EBEBF5);

  // ── Separators iOS ───────────────────────────────────────
  static const separatorLight = Color(0x4A3C3C43);
  static const separatorDark = Color(0x65545458);
  static const separatorOpaqueLight = Color(0xFFC6C6C8);
  static const separatorOpaqueDark = Color(0xFF38383A);

  // ── Accent (rose Apple Music) ────────────────────────────
  static const accent = Color(0xFFFC3C44); // rouge Apple Music
  static const accentSecondary = Color(0xFFFF6B6B);

  // ── Glass primitives ─────────────────────────────────────
  // Light : fond blanc semi-transparent
  static const glassFillLight = Color(0x8DFFFFFF); // 55%
  static const glassBorderLight = Color(0x99FFFFFF); // 60%
  static const glassHighlightLight = Color(0x33FFFFFF); // 20%

  // Dark : fond blanc très léger sur fond noir
  static const glassFillDark = Color(0x14FFFFFF); // 8%
  static const glassBorderDark = Color(0x1FFFFFFF); // 12%
  static const glassHighlightDark = Color(0x0DFFFFFF); // 5%

  // ── Vibrancy (texte sur glass) ───────────────────────────
  // Apple Vibrancy = texte blanc/noir adapté selon le fond derrière le verre
  static const vibrancyLabelLight = Color(0xFF000000);
  static const vibrancyLabelDark = Color(0xFFFFFFFF);
  static const vibrancySecondaryLight = Color(0x993C3C43);
  static const vibrancySecondaryDark = Color(0x99EBEBF5);
}
