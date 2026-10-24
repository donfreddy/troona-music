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

  // Dark: pure black base, glass only reads well on true black.
  // Surfaces sampled from the reference design (mini player body #07090E).
  static const bgPrimaryDark = Color(0xFF000000);
  static const bgSecondaryDark = Color(0xFF07090E);
  static const bgTertiaryDark = Color(0xFF0C0E14);
  static const bgElevatedDark = Color(0xFF14161D);

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

  // ── Accent (lilas / indigo) ──────────────────────────────
  static const accent = Color(0xFFB79CFF); // lilac, readable on black
  static const accentForeground = Color(0xFF12081F); // dark text on lilac
  static const accentGlow = Color(0xFF261548); // active tab glow (sampled)

  // ── Progress (icy blue to white arc) ─────────────────────
  static const progressStart = Color(0xFF8FB4FF);
  static const progressEnd = Color(0xFFFFFFFF);

  // ── Ambient background fallback (no artwork) ─────────────
  static const ambientTop = Color(0xFFA670AB); // top glow (sampled)
  static const ambientEdge = Color(0xFF644573); // glow edges (sampled)

  // ── Glass primitives (DEEP GLASS STYLE) ──────────────────
  // Light : fond blanc semi-transparent
  static const glassFillLight = Color(0x8DFFFFFF); // 55%
  static const glassBorderLight = Color(0x99FFFFFF); // 60%
  static const glassHighlightLight = Color(0x33FFFFFF); // 20%

  // Dark : "Deep Glass" — beaucoup plus sombre et transparent
  static const glassFillDark = Color(
    0x08FFFFFF,
  ); // 3% - Ultra thin for deep look
  static const glassBorderDark = Color(0x28FFFFFF); // 16% - Sharper highlight
  static const glassHighlightDark = Color(0x0FFFFFFF); // 6%

  // ── Vibrancy (texte sur glass) ───────────────────────────
  // Apple Vibrancy = texte blanc/noir adapté selon le fond derrière le verre
  static const vibrancyLabelLight = Color(0xFF000000);
  static const vibrancyLabelDark = Color(0xFFFFFFFF);
  static const vibrancySecondaryLight = Color(0x993C3C43);
  static const vibrancySecondaryDark = Color(0x99EBEBF5);
}
