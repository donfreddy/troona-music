import 'package:flutter/material.dart';

abstract final class ColorPrimitives {
  // ── Neutrals ─────────────────────────────────────────────
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);

  // ── Backgrounds ──────────────────────────────────────────
  // Pure black base, glass only reads well on true black.
  // Surfaces sampled from the reference design (mini player body #07090E).
  static const bgPrimaryDark = Color(0xFF000000);
  static const bgSecondaryDark = Color(0xFF07090E);
  static const bgTertiaryDark = Color(0xFF0C0E14);
  static const bgElevatedDark = Color(0xFF14161D);

  // ── Text ─────────────────────────────────────────────────
  static const labelPrimaryDark = Color(0xFFFFFFFF);
  static const labelSecondaryDark = Color(0x99EBEBF5);
  // Half alpha: 4.6:1 on black, text at any size (30 % gave 2.3:1).
  static const labelTertiaryDark = Color(0x80EBEBF5);
  static const labelQuaternaryDark = Color(0x29EBEBF5);

  // ── Separators ───────────────────────────────────────────
  static const separatorDark = Color(0x65545458);

  // ── Accent (lilac / indigo) ──────────────────────────────
  static const accent = Color(0xFFB79CFF); // lilac, readable on black
  static const accentForeground = Color(0xFF12081F); // dark text on lilac

  // ── Progress (light grey to white arc) ───────────────────
  // Neutral: it reads over every glow, and leaves the lilac the one accent
  // and the cover the one source of colour.
  static const progressStart = Color(0xFFC4C4CC);
  static const progressEnd = Color(0xFFFFFFFF);

  // ── Ambient background fallback (no artwork) ─────────────
  static const ambientTop = Color(0xFFA670AB); // top glow (sampled)
  static const ambientEdge = Color(0xFF644573); // glow edges (sampled)

  // ── Quiet surfaces (not glass: see GlassTheme) ──────────

  static const subtleFillDark = Color(0x08FFFFFF); // 3 %
  static const hairlineDark = Color(0x28FFFFFF); // 16 %
  static const pressedInkDark = Color(0x0FFFFFFF); // 6 %
}
