import 'package:flutter/material.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart'
    as troona_settings;

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

/// Quality presets to balance fidelity vs. performance.
/// Reuses the enum from settings to stay in sync.
typedef GlassQuality = troona_settings.GlassQuality;

abstract final class GlassTheme {
  static GlassQuality? _override;

  /// Allow a global override (e.g. user toggle “Reduce effects”).
  static void overrideQuality(GlassQuality? quality) => _override = quality;

  static GlassQuality _resolveQuality(BuildContext ctx, [GlassQuality? q]) {
    if (q != null) return q;
    if (_override != null) return _override!;

    final mq = MediaQuery.of(ctx);
    final shortest = mq.size.shortestSide;
    final lowTier = mq.devicePixelRatio < 2.0 || shortest < 360;
    return lowTier ? GlassQuality.low : GlassQuality.high;
  }

  // ── Light ────────────────────────────────────────────────
  static GlassConfig card(BuildContext ctx, {GlassQuality? quality}) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final q = _resolveQuality(ctx, quality);
    return switch ((isDark, q)) {
      (_, GlassQuality.off) => isDark ? _cardOffDark : _cardOffLight,
      (true, GlassQuality.low) => _cardLowDark,
      (false, GlassQuality.low) => _cardLowLight,
      (true, GlassQuality.high) => _cardDark,
      (false, GlassQuality.high) => _cardLight,
    };
  }

  static GlassConfig miniPlayer(BuildContext ctx, {GlassQuality? quality}) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final q = _resolveQuality(ctx, quality);
    return switch ((isDark, q)) {
      (_, GlassQuality.off) => isDark ? _cardOffDark : _cardOffLight,
      (true, GlassQuality.low) => _miniPlayerLowDark,
      (false, GlassQuality.low) => _miniPlayerLowLight,
      (true, GlassQuality.high) => _miniPlayerDark,
      (false, GlassQuality.high) => _miniPlayerLight,
    };
  }

  static GlassConfig nowPlaying(BuildContext ctx, {GlassQuality? quality}) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final q = _resolveQuality(ctx, quality);
    return switch ((isDark, q)) {
      (_, GlassQuality.off) => isDark ? _cardOffDark : _cardOffLight,
      (true, GlassQuality.low) => _nowPlayingLowDark,
      (false, GlassQuality.low) => _nowPlayingLowLight,
      (true, GlassQuality.high) => _nowPlayingDark,
      (false, GlassQuality.high) => _nowPlayingLight,
    };
  }

  static GlassConfig sheet(BuildContext ctx, {GlassQuality? quality}) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final q = _resolveQuality(ctx, quality);
    return switch ((isDark, q)) {
      (_, GlassQuality.off) => isDark ? _sheetOffDark : _sheetOffLight,
      (true, GlassQuality.low) => _sheetLowDark,
      (false, GlassQuality.low) => _sheetLowLight,
      (true, GlassQuality.high) => _sheetDark,
      (false, GlassQuality.high) => _sheetLight,
    };
  }

  // ── Configs Light (iOS 17/18 inspired) ───────────────────
  static const _cardLight = GlassConfig(
    blurSigma: 14,
    fill: Color(0x8CFFFFFF), // ~55%
    border: Color(0x16FFFFFF), // ~9%
    highlight: Color(0x0DFFFFFF), // ~5%
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  static const _miniPlayerLight = GlassConfig(
    blurSigma: 24,
    fill: Color(0xA6FFFFFF), // ~65%
    border: Color(0x21FFFFFF), // ~13%
    highlight: Color(0x0FFFFFFF),
    borderRadius: BorderRadius.all(Radius.circular(16)),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );

  static const _nowPlayingLight = GlassConfig(
    blurSigma: 26,
    fill: Color(0x73FFFFFF), // ~45%
    border: Color(0x21FFFFFF),
    highlight: Color(0x0DFFFFFF),
    borderRadius: BorderRadius.all(Radius.circular(0)), // plein écran
    padding: EdgeInsets.zero,
  );

  static const _sheetLight = GlassConfig(
    blurSigma: 24,
    fill: Color(0xA6FFFFFF),
    border: Color(0x1EFFFFFF),
    highlight: Color(0x0DFFFFFF),
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
  );

  // ── Configs Dark ─────────────────────────────────────────
  static const _cardDark = GlassConfig(
    blurSigma: 14,
    fill: Color(0x14FFFFFF), // ~8%
    border: Color(0x1FFFFFFF), // ~12%
    highlight: Color(0x0DFFFFFF), // ~5%
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  static const _miniPlayerDark = GlassConfig(
    blurSigma: 24,
    fill: Color(0x16FFFFFF), // ~9%
    border: Color(0x21FFFFFF), // ~13%
    highlight: Color(0x0DFFFFFF),
    borderRadius: BorderRadius.all(Radius.circular(16)),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );

  static const _nowPlayingDark = GlassConfig(
    blurSigma: 26,
    fill: Color(0x10FFFFFF), // ~6%
    border: Color(0x16FFFFFF),
    highlight: Color(0x0AFFFFFF),
    borderRadius: BorderRadius.all(Radius.circular(0)),
    padding: EdgeInsets.zero,
  );

  static const _sheetDark = GlassConfig(
    blurSigma: 24,
    fill: Color(0x19FFFFFF), // ~10%
    border: Color(0x16FFFFFF),
    highlight: Color(0x0AFFFFFF),
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
  );

  // ── Low quality (halve blur, boost fill) ─────────────────
  static const _cardLowLight = GlassConfig(
    blurSigma: 8,
    fill: Color(0xA0FFFFFF),
    border: Color(0x11FFFFFF),
    highlight: Color(0x0AFFFFFF),
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );
  static const _cardLowDark = GlassConfig(
    blurSigma: 8,
    fill: Color(0x1EFFFFFF),
    border: Color(0x12FFFFFF),
    highlight: Color(0x08FFFFFF),
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );
  static const _miniPlayerLowLight = GlassConfig(
    blurSigma: 12,
    fill: Color(0xB0FFFFFF),
    border: Color(0x18FFFFFF),
    highlight: Color(0x0AFFFFFF),
    borderRadius: BorderRadius.all(Radius.circular(16)),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );
  static const _miniPlayerLowDark = GlassConfig(
    blurSigma: 12,
    fill: Color(0x24FFFFFF),
    border: Color(0x12FFFFFF),
    highlight: Color(0x08FFFFFF),
    borderRadius: BorderRadius.all(Radius.circular(16)),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );
  static const _nowPlayingLowLight = GlassConfig(
    blurSigma: 14,
    fill: Color(0x82FFFFFF),
    border: Color(0x16FFFFFF),
    highlight: Color(0x0AFFFFFF),
    borderRadius: BorderRadius.all(Radius.circular(0)),
    padding: EdgeInsets.zero,
  );
  static const _nowPlayingLowDark = GlassConfig(
    blurSigma: 14,
    fill: Color(0x16FFFFFF),
    border: Color(0x10FFFFFF),
    highlight: Color(0x08FFFFFF),
    borderRadius: BorderRadius.all(Radius.circular(0)),
    padding: EdgeInsets.zero,
  );
  static const _sheetLowLight = GlassConfig(
    blurSigma: 14,
    fill: Color(0xB5FFFFFF),
    border: Color(0x16FFFFFF),
    highlight: Color(0x0AFFFFFF),
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
  );
  static const _sheetLowDark = GlassConfig(
    blurSigma: 14,
    fill: Color(0x21FFFFFF),
    border: Color(0x12FFFFFF),
    highlight: Color(0x08FFFFFF),
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
  );

  // ── Off (no blur, flat tint) ─────────────────────────────
  static const _cardOffLight = GlassConfig(
    blurSigma: 0,
    fill: Color(0xE6F2F2F7),
    border: Colors.transparent,
    highlight: Colors.transparent,
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );
  static const _cardOffDark = GlassConfig(
    blurSigma: 0,
    fill: Color(0xE60D0D10),
    border: Colors.transparent,
    highlight: Colors.transparent,
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );
  static const _sheetOffLight = GlassConfig(
    blurSigma: 0,
    fill: Color(0xFFF5F5F7),
    border: Colors.transparent,
    highlight: Colors.transparent,
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
  );
  static const _sheetOffDark = GlassConfig(
    blurSigma: 0,
    fill: Color(0xFF1C1C1E),
    border: Colors.transparent,
    highlight: Colors.transparent,
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
  );
}
