import 'package:flutter/material.dart';

@immutable
final class GlassConfig {
  final double blurSigma; // intensité du BackdropFilter
  final Color fill; // couleur de fond
  final Color border; // bordure supérieure (reflet)
  final Color highlight; // reflet diagonal subtil
  final double borderWidth;
  final BorderRadius borderRadius;
  final EdgeInsets padding;

  const GlassConfig({
    required this.blurSigma,
    required this.fill,
    required this.border,
    required this.highlight,
    this.borderWidth = 0.5,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding = const EdgeInsets.all(16),
  });
}

abstract final class GlassTheme {
  // ── Light ────────────────────────────────────────────────
  static GlassConfig card(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return isDark ? _cardDark : _cardLight;
  }

  static GlassConfig miniPlayer(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return isDark ? _miniPlayerDark : _miniPlayerLight;
  }

  static GlassConfig nowPlaying(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return isDark ? _nowPlayingDark : _nowPlayingLight;
  }

  static GlassConfig sheet(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return isDark ? _sheetDark : _sheetLight;
  }

  // ── Configs Light ────────────────────────────────────────
  static const _cardLight = GlassConfig(
    blurSigma: 20,
    fill: Color(0x8DFFFFFF), // 55% blanc
    border: Color(0x99FFFFFF), // 60% blanc
    highlight: Color(0x1AFFFFFF), // 10%
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  static const _miniPlayerLight = GlassConfig(
    blurSigma: 28, // plus fort pour le mini player
    fill: Color(0xB3FFFFFF), // 70%
    border: Color(0xCCFFFFFF), // 80%
    highlight: Color(0x26FFFFFF),
    borderRadius: BorderRadius.all(Radius.circular(16)),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );

  static const _nowPlayingLight = GlassConfig(
    blurSigma: 40, // maximum — fond artwork flouté
    fill: Color(0x66FFFFFF), // 40%
    border: Color(0x80FFFFFF), // 50%
    highlight: Color(0x33FFFFFF),
    borderRadius: BorderRadius.all(Radius.circular(0)), // plein écran
    padding: EdgeInsets.zero,
  );

  static const _sheetLight = GlassConfig(
    blurSigma: 24,
    fill: Color(0xCCF2F2F7), // gris iOS + transparence
    border: Color(0x99FFFFFF),
    highlight: Color(0x1AFFFFFF),
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
  );

  // ── Configs Dark ─────────────────────────────────────────
  static const _cardDark = GlassConfig(
    blurSigma: 20,
    fill: Color(0x14FFFFFF), // 8% blanc sur noir
    border: Color(0x1FFFFFFF), // 12%
    highlight: Color(0x0DFFFFFF), // 5%
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  static const _miniPlayerDark = GlassConfig(
    blurSigma: 28,
    fill: Color(0x1FFFFFFF), // 12%
    border: Color(0x29FFFFFF), // 16%
    highlight: Color(0x0DFFFFFF),
    borderRadius: BorderRadius.all(Radius.circular(16)),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );

  static const _nowPlayingDark = GlassConfig(
    blurSigma: 40,
    fill: Color(0x0DFFFFFF), // 5% — artwork domine
    border: Color(0x1AFFFFFF),
    highlight: Color(0x0AFFFFFF),
    borderRadius: BorderRadius.all(Radius.circular(0)),
    padding: EdgeInsets.zero,
  );

  static const _sheetDark = GlassConfig(
    blurSigma: 24,
    fill: Color(0xCC1C1C1E), // gris foncé iOS
    border: Color(0x1FFFFFFF),
    highlight: Color(0x0DFFFFFF),
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
  );
}
