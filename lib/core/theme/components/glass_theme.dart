import 'package:flutter/material.dart';
import 'package:troona/core/theme/components/blur_budget.dart';
import 'package:troona/core/theme/components/glass_filter.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart'
    as troona_settings;

/// The material of one glass surface: how much it blurs and tints what is
/// behind it, and the edge drawn around it.
///
/// **Rendering contract** (enforced at the call site, e.g. [GlassCard]):
/// - When [blurSigma] == 0 skip [BackdropFilter] entirely (fast path).
/// - Always wrap [BackdropFilter] in a [RepaintBoundary].
/// - Never place inside an [AnimatedBuilder] driven by audio position.
@immutable
final class GlassConfig {
  /// Blur of what is behind the glass, in logical pixels ([GlassFilter.of]):
  /// 30 on the bars and sheets, 26 on Now Playing's dock, 20 on cards that
  /// opt into a blur. 0 is the flat fast path, without a [BackdropFilter].
  final double blurSigma;

  /// Tint drawn over the blur.
  final Color fill;

  /// Colour of the edge where light catches it, at the top.
  final Color border;

  /// Colour of the edge down the sides, where it fades from [border].
  final Color highlight;

  /// Width of the edge, in logical pixels; 0 draws none.
  final double borderWidth;

  final BorderRadius borderRadius;
  final EdgeInsets padding;

  /// Saturation boost behind the glass ([GlassFilter]). Surfaces that carry
  /// text (bars, header, sheets) use 1, so covers and icons behind them do
  /// not show as stains; decorative glass over artwork keeps the boost.
  final double saturation;

  /// Brightness of what the glass lets through ([GlassFilter.of]): 1 for
  /// most glass; below 1 where text sits on whatever scrolls under it with
  /// nothing to darken it first (the page header).
  final double exposure;

  const GlassConfig({
    required this.blurSigma,
    required this.fill,
    required this.border,
    required this.highlight,
    this.borderWidth = 0.5,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding = const EdgeInsets.all(16),
    this.saturation = GlassFilter.saturation,
    this.exposure = 1,
  });

  GlassConfig copyWith({
    double? blurSigma,
    Color? fill,
    Color? border,
    Color? highlight,
    double? borderWidth,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    double? saturation,
    double? exposure,
  }) {
    return GlassConfig(
      blurSigma: blurSigma ?? this.blurSigma,
      fill: fill ?? this.fill,
      border: border ?? this.border,
      highlight: highlight ?? this.highlight,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      saturation: saturation ?? this.saturation,
      exposure: exposure ?? this.exposure,
    );
  }
}

/// Typedef so consumers use a single [GlassQuality] symbol without a manual
/// alias; the enum is defined once in [AppSettings] (single source of truth).
typedef GlassQuality = troona_settings.GlassQuality;

/// Resolves the [GlassConfig] of each surface for a [GlassQuality] tier.
///
/// ### Quality tiers
///
/// | Tier  | Blur                          | Purpose                          |
/// |-------|-------------------------------|----------------------------------|
/// | high  | 30 on chrome, 26 on the dock  | Default on capable devices       |
/// | low   | 8 to 14                       | Devices detected as modest       |
/// | off   | none                          | Flat tint, no [BackdropFilter]   |
///
/// ### Auto-detection ([GlassTier.detect], at start-up)
///
/// Android with under 3 GB of RAM gets [GlassQuality.off]; under 6 GB, or
/// below Android 10, [GlassQuality.low]; otherwise [GlassQuality.high].
/// "Remove animations" gets [GlassQuality.off]. The user's glass quality
/// setting overrides it ([overrideQuality]).
abstract final class GlassTheme {
  /// Quality override set by [overrideQuality] (from user settings).
  static GlassQuality? _override;

  /// Tier detected at startup by [GlassTier.detect].
  static GlassQuality _detectedTier = GlassQuality.high;

  /// Called once from [configureDependencies] with the hardware-detected tier.
  static void setDetectedTier(GlassQuality tier) => _detectedTier = tier;

  /// Overrides the auto-detected quality for all surfaces.
  ///
  /// Pass `null` to re-enable auto-detection (i.e. user chose [GlassQuality.auto]).
  /// Typically called from [SettingsCubit.setGlassQuality].
  static void overrideQuality(GlassQuality? quality) => _override = quality;

  /// Resolves the effective [GlassQuality] for [ctx].
  ///
  /// Priority: explicit [q] argument > [_override] > [_detectedTier].
  /// [GlassQuality.auto] is never returned; it always falls through to detection.
  static GlassQuality _resolveQuality(BuildContext ctx, [GlassQuality? q]) {
    if (q != null && q != GlassQuality.auto) return q;
    if (_override != null && _override != GlassQuality.auto) return _override!;
    return _detectedTier;
  }

  /// Resolves the effective [GlassQuality] for [ctx].
  static GlassQuality resolveQuality(BuildContext ctx, [GlassQuality? q]) =>
      _resolveQuality(ctx, q);

  /// Quality for a short-lived surface over glass that already blurs (a
  /// modal sheet above the tab bar), opened from [ctx]: a third blur only
  /// where the device is high-tier, opaque otherwise, and always opaque
  /// below a [BlurBudgetSpent]. See the blur budget in CLAUDE.md.
  static GlassQuality aboveGlass(BuildContext ctx) =>
      !BlurBudgetSpent.isSpent(ctx) && _resolveQuality(ctx) == GlassQuality.high
      ? GlassQuality.high
      : GlassQuality.off;

  // ── Public surface accessors ─────────────────────────────────────────────

  /// Config for standard content cards (albums, playlists, info panels).
  static GlassConfig card(BuildContext ctx, {GlassQuality? quality}) {
    final q = _resolveQuality(ctx, quality);
    return switch (q) {
      GlassQuality.off => _cardOffDark,
      GlassQuality.low => _cardLowDark,
      _ => _cardDark,
    };
  }

  /// Config for cards in scrolling content (Home's cards, Settings'
  /// groups): flat, no edge, the fill alone, grouped by spacing. On the
  /// high tier the fill is a step above [card]'s, which leans on its edge
  /// to show: without one, 4 % white barely parts from the page.
  static GlassConfig content(BuildContext ctx, {GlassQuality? quality}) {
    final high = _resolveQuality(ctx, quality) == GlassQuality.high;
    return card(ctx, quality: quality).copyWith(
      blurSigma: 0,
      borderWidth: 0,
      fill: high ? contentFillDark : null,
    );
  }

  /// [content]'s fill on the high tier: 8 % white, the low end
  /// of `.ultraThinMaterial` (the low tier's card fill is 12 %).
  static const Color contentFillDark = Color(0x14FFFFFF);

  /// Config for chrome that carries text and controls: the tab bar (with
  /// the mini player inside it) and the collapsed page header. A light dark
  /// tint and a mild saturation: covers behind stay rich without showing as
  /// stains.
  static GlassConfig bar(BuildContext ctx, {GlassQuality? quality}) {
    final q = _resolveQuality(ctx, quality);
    return switch (q) {
      GlassQuality.off => _cardOffDark,
      GlassQuality.low => _barLowDark,
      _ => _barDark,
    };
  }

  /// Config for the collapsed page header ([GlassSliverHeader]): the
  /// [bar] glass, exposed at [headerExposure]. Covers scroll right under
  /// its title, unlike the tab bar's, which the shell darkens first: a
  /// white one under 15 % of tint left white text at 1.4:1. On the low
  /// tier the header takes the dark tint too: the white veil, exposed or
  /// not, stays near 3:1.
  static GlassConfig header(BuildContext ctx, {GlassQuality? quality}) {
    final bar = GlassTheme.bar(ctx, quality: quality);
    if (bar.blurSigma == 0) return bar;
    return bar.copyWith(fill: _barDark.fill, exposure: headerExposure);
  }

  /// Brightness of what the header's glass lets through: white text keeps
  /// about 5:1 over a white cover under the [bar] tint.
  static const double headerExposure = 0.5;

  /// The mini player's edge, inside the tab bar's glass.
  static GlassConfig miniPlayer(BuildContext ctx, {GlassQuality? quality}) {
    final q = _resolveQuality(ctx, quality);
    return switch (q) {
      GlassQuality.off => _cardOffDark,
      GlassQuality.low => _miniPlayerLowDark,
      _ => _miniPlayerDark,
    };
  }

  /// The blur of Now Playing's dock.
  static GlassConfig nowPlaying(BuildContext ctx, {GlassQuality? quality}) {
    final q = _resolveQuality(ctx, quality);
    return switch (q) {
      GlassQuality.off => _cardOffDark,
      GlassQuality.low => _nowPlayingLowDark,
      _ => _nowPlayingDark,
    };
  }

  /// Config for bottom sheets (queue sheet, context menu, etc.).
  ///
  /// Top corners are rounded (20 px); bottom corners are square to bleed
  /// to the screen edge.  Top padding (8 px) reserves space for the drag handle.
  static GlassConfig sheet(BuildContext ctx, {GlassQuality? quality}) {
    final q = _resolveQuality(ctx, quality);
    return switch (q) {
      GlassQuality.off => _sheetOffDark,
      GlassQuality.low => _sheetLowDark,
      _ => _sheetDark,
    };
  }

  // ── High quality ────────────────────────────────────────────────────────

  static const _cardDark = GlassConfig(
    blurSigma: 20,
    fill: Color(0x0AFFFFFF), // 4 %: Much darker for "Deep Glass" look
    border: Color(0x22FFFFFF), // 13 %: Sharper edge highlight
    highlight: Color(0x0DFFFFFF), // 5 %
    borderRadius: BorderRadius.all(Radius.circular(24)),
  );

  static const _miniPlayerDark = GlassConfig(
    blurSigma: 28, // Heavy blur for the pill
    fill: Color(0x08FFFFFF), // 3 %
    border: Color(0x28FFFFFF), // 16 %: Brighter edge to define the pill
    highlight: Color(0x0FFFFFFF), // 6 %
    borderRadius: BorderRadius.all(Radius.circular(40)), // Pill shape
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  );

  static const _nowPlayingDark = GlassConfig(
    blurSigma: 26,
    fill: Color(0x10FFFFFF), // 6 %: very thin to let artwork breathe
    border: Color(0x16FFFFFF), // 9 %
    highlight: Color(0x0AFFFFFF), // 4 %
    borderRadius: BorderRadius.zero, // full-screen: no rounded corners
    padding: EdgeInsets.zero,
  );

  // Between the thin glass (stains) and a thick material (too dim): the
  // blur spreads small shapes, the tint tempers what the boost revives.
  static const _barDark = GlassConfig(
    blurSigma: 30,
    fill: Color(0x260C0E14), // 15 % tertiary background
    border: Color(0x22FFFFFF), // 13 %
    highlight: Color(0x0DFFFFFF), // 5 %
    borderRadius: BorderRadius.all(Radius.circular(24)),
    saturation: 1.25,
  );

  static const _barLowDark = GlassConfig(
    blurSigma: 8,
    fill: Color(0x1EFFFFFF), // 12 %
    border: Color(0x12FFFFFF), // 7 %
    highlight: Color(0x08FFFFFF), // 3 %
    borderRadius: BorderRadius.all(Radius.circular(20)),
    saturation: 1,
  );

  // Same glass as [_barDark].
  static const _sheetDark = GlassConfig(
    blurSigma: 30,
    fill: Color(0x260C0E14), // 15 % tertiary background
    border: Color(0x16FFFFFF), // 9 %
    highlight: Color(0x0AFFFFFF), // 4 %
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
    saturation: 1.25,
  );

  // ── Low quality ─────────────────────────────────────────────────────────

  static const _cardLowDark = GlassConfig(
    blurSigma: 8,
    fill: Color(0x1EFFFFFF), // 12 %: boosted vs. high quality's 4 %
    border: Color(0x12FFFFFF), // 7 %
    highlight: Color(0x08FFFFFF), // 3 %
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  static const _miniPlayerLowDark = GlassConfig(
    blurSigma: 12,
    fill: Color(0x24FFFFFF), // 14 %
    border: Color(0x12FFFFFF), // 7 %
    highlight: Color(0x08FFFFFF), // 3 %
    borderRadius: BorderRadius.all(Radius.circular(16)),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );

  static const _nowPlayingLowDark = GlassConfig(
    blurSigma: 14,
    fill: Color(0x16FFFFFF), // 9 %
    border: Color(0x10FFFFFF), // 6 %
    highlight: Color(0x08FFFFFF), // 3 %
    borderRadius: BorderRadius.zero,
    padding: EdgeInsets.zero,
  );

  static const _sheetLowDark = GlassConfig(
    blurSigma: 14,
    fill: Color(0x21FFFFFF), // 13 %
    border: Color(0x12FFFFFF), // 7 %
    highlight: Color(0x08FFFFFF), // 3 %
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
    saturation: 1,
  );

  // ── Off: flat tint, no BackdropFilter ───────────────────────────────────
  //
  // [blurSigma] == 0 triggers the fast path in GlassCard (no compositing layer).

  static const _cardOffDark = GlassConfig(
    blurSigma: 0,
    fill: Color(0xE61C1C1E), // 90 % secondarySystemBackground dark
    border: Colors.transparent,
    highlight: Colors.transparent,
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  static const _sheetOffDark = GlassConfig(
    blurSigma: 0,
    fill: Color(0xFF1C1C1E), // secondarySystemBackground dark (opaque)
    border: Colors.transparent,
    highlight: Colors.transparent,
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
  );
}
