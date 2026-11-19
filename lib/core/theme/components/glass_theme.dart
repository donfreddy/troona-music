import 'package:flutter/material.dart';
import 'package:troona/core/theme/components/blur_budget.dart';
import 'package:troona/core/theme/components/glass_filter.dart';
import 'package:troona/core/theme/components/glass_settings.dart';
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
  /// text (bars, header, sheets) take a mild 1.25 under their tint, so
  /// covers and icons behind them do not show as stains; decorative glass
  /// over artwork (the lens, the dock) keeps the full boost.
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
/// | Tier               | Blur                                     |
/// |--------------------|------------------------------------------|
/// | high (Full)        | 30 on chrome, 26 on the dock; sheets too |
/// | low (Balanced)     | The page header alone, at 30             |
/// | off (No blur)      | None                                     |
///
/// A tier saves by blurring fewer and smaller surfaces, never by a smaller
/// sigma: Impeller blurs a large sigma on a smaller image, so the cost is
/// in capturing what is behind, per filter and per pixel. Balanced keeps
/// the header's blur, where sharp lines of text pass under its title; the
/// tab bar, whose content the shell darkens first, turns to an 88 % tint
/// with its edge, Now Playing's lens and dock to a light veil, sheets
/// opaque. No blur stays a drawn surface: tints from the palette, with
/// their edge.
///
/// ### Auto-detection ([GlassTier.detect], at start-up)
///
/// Android with under 3 GB of RAM gets [GlassQuality.off]; under 6 GB, or
/// below Android 10, [GlassQuality.low]; otherwise [GlassQuality.high].
/// "Remove animations" gets [GlassQuality.off]. The user's glass quality
/// setting overrides it. The app resolves both into the theme's
/// [GlassSettings], which every accessor reads.
abstract final class GlassTheme {
  /// The quality [ctx] draws with: [q] when given (not auto), else the
  /// theme's [GlassSettings], else high (a theme without it, in tests).
  static GlassQuality _resolveQuality(BuildContext ctx, [GlassQuality? q]) {
    if (q != null && q != GlassQuality.auto) return q;
    final themed = Theme.of(ctx).extension<GlassSettings>()?.quality;
    // Never auto past here: every surface agrees on one tier.
    return themed == null || themed == GlassQuality.auto
        ? GlassQuality.high
        : themed;
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
      GlassQuality.off => _barOffDark,
      GlassQuality.low => _barLowDark,
      _ => _barDark,
    };
  }

  /// Config for the collapsed page header ([GlassSliverHeader]): the
  /// high tier's [bar] glass, exposed at [headerExposure], on the
  /// balanced tier too (the one blur it keeps). Covers scroll right under
  /// its title, unlike the tab bar's, which the shell darkens first: a
  /// white one under 15 % of tint left white text at 1.4:1. Without blur,
  /// the bar's opaque tint.
  static GlassConfig header(BuildContext ctx, {GlassQuality? quality}) =>
      switch (_resolveQuality(ctx, quality)) {
        GlassQuality.off => _barOffDark,
        _ => _barDark.copyWith(exposure: headerExposure),
      };

  /// Brightness of what the header's glass lets through: white text keeps
  /// about 5:1 over a white cover under the [bar] tint.
  static const double headerExposure = 0.5;

  /// The tint of the mini player's progress, inside the tab bar's glass:
  /// the bar's edge, a step brighter where the bar blurs.
  static Color miniPlayerTint(BuildContext ctx, {GlassQuality? quality}) =>
      switch (_resolveQuality(ctx, quality)) {
        GlassQuality.high || GlassQuality.auto => const Color(0x28FFFFFF),
        _ => _barLowDark.border,
      };

  /// Now Playing's dock: blurred on the high tier, the same veil without
  /// blur below it.
  static GlassConfig nowPlaying(BuildContext ctx, {GlassQuality? quality}) =>
      switch (_resolveQuality(ctx, quality)) {
        GlassQuality.high || GlassQuality.auto => _nowPlayingDark,
        _ => _nowPlayingDark.copyWith(blurSigma: 0),
      };

  /// Now Playing's lens: a light frost on the high tier (enough to blur
  /// the neighbour covers, cheap at that sigma), the same veil without
  /// blur below it.
  static GlassConfig lens(BuildContext ctx, {GlassQuality? quality}) =>
      switch (_resolveQuality(ctx, quality)) {
        GlassQuality.high || GlassQuality.auto => _lensDark,
        _ => _lensDark.copyWith(blurSigma: 0),
      };

  /// Config for bottom sheets (queue sheet, context menu, etc.).
  ///
  /// Top corners are rounded (20 px); bottom corners are square to bleed
  /// to the screen edge.  Top padding (8 px) reserves space for the drag handle.
  /// Opaque below the high tier.
  static GlassConfig sheet(BuildContext ctx, {GlassQuality? quality}) =>
      switch (_resolveQuality(ctx, quality)) {
        GlassQuality.high || GlassQuality.auto => _sheetDark,
        _ => _sheetOffDark,
      };

  // ── High quality ────────────────────────────────────────────────────────

  static const _cardDark = GlassConfig(
    blurSigma: 20,
    fill: Color(0x0AFFFFFF), // 4 %: Much darker for "Deep Glass" look
    border: Color(0x22FFFFFF), // 13 %: Sharper edge highlight
    highlight: Color(0x0DFFFFFF), // 5 %
    borderRadius: BorderRadius.all(Radius.circular(24)),
  );

  static const _nowPlayingDark = GlassConfig(
    blurSigma: 26,
    fill: Color(0x0AFFFFFF), // 4 %: the covers show through
    border: Color(0x1FFFFFFF), // 12 %
    highlight: Color(0x0DFFFFFF), // 5 %
    borderWidth: 0.8,
    borderRadius: BorderRadius.all(Radius.circular(999)), // a pill
    padding: EdgeInsets.symmetric(horizontal: 4),
  );

  // The lens draws its own rim; only the blur and the veil are read.
  static const _lensDark = GlassConfig(
    blurSigma: 12,
    fill: Color(0x14FFFFFF), // 8 %
    border: Color(0x00000000),
    highlight: Color(0x00000000),
    borderWidth: 0,
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

  // Balanced: an opaque tint, the high tier's edge.
  static const _barLowDark = GlassConfig(
    blurSigma: 0,
    fill: Color(0xE00C0E14), // 88 % tertiary background
    border: Color(0x22FFFFFF), // 13 %
    highlight: Color(0x0DFFFFFF), // 5 %
    borderRadius: BorderRadius.all(Radius.circular(24)),
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

  // ── Balanced (low) ──────────────────────────────────────────────────

  // No blur: every card is flat.
  static const _cardLowDark = GlassConfig(
    blurSigma: 0,
    fill: Color(0x1EFFFFFF), // 12 %: boosted vs. high quality's 4 %
    border: Color(0x12FFFFFF), // 7 %
    highlight: Color(0x08FFFFFF), // 3 %
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  // ── Off: flat tint, no BackdropFilter ───────────────────────────────────
  //
  // [blurSigma] == 0 triggers the fast path in GlassCard (no compositing layer).

  // Palette tints, never iOS's neutral grey, and the edge kept.
  static const _cardOffDark = GlassConfig(
    blurSigma: 0,
    fill: Color(0xF014161D), // 94 % elevated background
    border: Color(0x22FFFFFF), // 13 %
    highlight: Color(0x0DFFFFFF), // 5 %
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  static const _barOffDark = GlassConfig(
    blurSigma: 0,
    fill: Color(0xF00C0E14), // 94 % tertiary background
    border: Color(0x22FFFFFF), // 13 %
    highlight: Color(0x0DFFFFFF), // 5 %
    borderRadius: BorderRadius.all(Radius.circular(24)),
  );

  static const _sheetOffDark = GlassConfig(
    blurSigma: 0,
    fill: Color(0xFF14161D), // elevated background, opaque
    border: Color(0x16FFFFFF), // 9 %
    highlight: Color(0x0AFFFFFF), // 4 %
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
  );
}
