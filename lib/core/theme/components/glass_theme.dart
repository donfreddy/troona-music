import 'package:flutter/material.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart'
    as troona_settings;

/// Immutable configuration object for a single glassmorphism surface.
///
/// All blur/fill/border values are calibrated against iOS 17/18 UIKit
/// material constants ([UIBlurEffect], [UIVibrancyEffect]).
///
/// **Rendering contract** (enforced at the call site, e.g. [GlassCard]):
/// - When [blurSigma] == 0 skip [BackdropFilter] entirely (fast path).
/// - Always wrap [BackdropFilter] in a [RepaintBoundary].
/// - Never place inside an [AnimatedBuilder] driven by audio position.
@immutable
final class GlassConfig {
  /// Gaussian blur radius passed to [ImageFilter.blur].
  ///
  /// Values are in logical pixels.  Approximate iOS equivalents:
  /// - 14 px → UIBlurEffectStyleLight / Dark (regular material)
  /// - 24 px → UIBlurEffectStyleSystemUltraThinMaterial (mini-player bar)
  /// - 26 px → full-screen now-playing overlay
  ///
  /// Set to 0 to use the flat-tint fast path (no [BackdropFilter] cost).
  final double blurSigma;

  /// Background fill colour drawn behind the blur layer.
  ///
  /// Dark mode targets 6–12 % white alpha to match iOS `.ultraThinMaterial`
  /// and `.thinMaterial`.  Light mode targets 55–70 % white alpha.
  final Color fill;

  /// Top-edge highlight stroke that simulates a light-source reflection.
  ///
  /// Corresponds to the bright separator line visible at the top of iOS
  /// sheets and cards.  Typically 9–13 % white alpha on both themes.
  final Color border;

  /// Subtle diagonal sheen rendered as a second, lower-opacity overlay.
  ///
  /// Approximates the luminosity vibrancy pass iOS applies over materials.
  /// Keep below 5 % alpha to avoid washing out dark content.
  final Color highlight;

  /// Stroke width of the [border] line in logical pixels.
  ///
  /// 0.5 renders as exactly 1 physical pixel on 2× displays and is the
  /// standard iOS separator thickness.
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

/// Typedef so consumers use a single [GlassQuality] symbol without a manual
/// alias; the enum is defined once in [AppSettings] (single source of truth).
typedef GlassQuality = troona_settings.GlassQuality;

/// Resolves the correct [GlassConfig] for a given surface type, brightness,
/// and [GlassQuality] preset.
///
/// Call the named constructors ([card], [miniPlayer], [nowPlaying], [sheet])
/// inside a [BuildContext] — they read [MediaQuery] and [Theme] automatically.
///
/// ---
/// ### Quality tiers
///
/// | Tier  | Blur            | Purpose                                  |
/// |-------|-----------------|------------------------------------------|
/// | high  | 14–26 px        | Default on mid/high-end devices          |
/// | low   | 8–14 px         | Reduced blur + boosted fill on low-end   |
/// | off   | 0 px            | Flat tint, no [BackdropFilter] cost       |
///
/// ### Auto-detection heuristic ([_resolveQuality])
///
/// Devices with `devicePixelRatio < 2.0` or `shortestSide < 360` are
/// classified as low-tier and receive the [GlassQuality.low] preset
/// automatically.  Override at any time via [overrideQuality] (e.g. the
/// user's "Reduce transparency" setting).
///
/// ### iOS reference values
///
/// Dark-mode fills target Apple's `.ultraThinMaterial` range (6–12 % white).
/// Light-mode fills target `.regularMaterial` / `.thinMaterial` (55–70 %).
/// Blur sigmas are in logical pixels; multiply by [devicePixelRatio] for the
/// equivalent UIKit blur radius.
abstract final class GlassTheme {
  /// Global quality override set by [overrideQuality].
  static GlassQuality? _override;

  /// Overrides the auto-detected quality for all surfaces.
  ///
  /// Pass `null` to re-enable auto-detection.
  /// Typically called from [SettingsCubit.setGlassQuality].
  static void overrideQuality(GlassQuality? quality) => _override = quality;

  /// Resolves the effective [GlassQuality] for [ctx].
  ///
  /// Priority: explicit [q] argument > [_override] > auto-detection heuristic.
  static GlassQuality _resolveQuality(BuildContext ctx, [GlassQuality? q]) {
    if (q != null) return q;
    if (_override != null) return _override!;

    final mq = MediaQuery.of(ctx);
    final shortest = mq.size.shortestSide;
    // Low-tier heuristic: covers most Android entry-level devices and older
    // iPhones (SE 1st gen has shortestSide = 320).
    final lowTier = mq.devicePixelRatio < 2.0 || shortest < 360;
    return lowTier ? GlassQuality.low : GlassQuality.high;
  }

  // ── Public surface accessors ─────────────────────────────────────────────

  /// Config for standard content cards (albums, playlists, info panels).
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

  /// Config for the persistent mini-player bar (bottom of the shell).
  ///
  /// Uses heavier blur than [card] to match the iOS "Now Playing" bar
  /// appearance (`.systemUltraThinMaterial` territory).
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

  /// Config for the full-screen now-playing overlay.
  ///
  /// [borderRadius] is [BorderRadius.zero] — the overlay spans edge-to-edge.
  /// [padding] is [EdgeInsets.zero] — the page handles its own safe-area insets.
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

  /// Config for bottom sheets (queue sheet, context menu, etc.).
  ///
  /// Top corners are rounded (20 px); bottom corners are square to bleed
  /// to the screen edge.  Top padding (8 px) reserves space for the drag handle.
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

  // ── High quality — Light theme ───────────────────────────────────────────
  //
  // Targets iOS 17/18 `.thinMaterial` in light mode:
  //   fill   ~55 % white  (0x8C = 140/255 ≈ 55 %)
  //   border ~9 % white   (top-edge luminosity highlight)
  //   blur   14 px logical

  static const _cardLight = GlassConfig(
    blurSigma: 14,
    fill: Color(0x8CFFFFFF), // 55 % — iOS thinMaterial light
    border: Color(0x16FFFFFF), // 9 %  — top-edge luminosity highlight
    highlight: Color(0x0DFFFFFF), // 5 %  — diagonal sheen
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  static const _miniPlayerLight = GlassConfig(
    blurSigma: 24, // heavier blur — matches iOS "Now Playing" bar
    fill: Color(0xA6FFFFFF), // 65 % — regularMaterial light
    border: Color(0x21FFFFFF), // 13 %
    highlight: Color(0x0FFFFFFF), // 6 %
    borderRadius: BorderRadius.all(Radius.circular(16)),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );

  static const _nowPlayingLight = GlassConfig(
    blurSigma: 26,
    fill: Color(0x73FFFFFF), // 45 % — slightly transparent for artwork to show
    border: Color(0x21FFFFFF), // 13 %
    highlight: Color(0x0DFFFFFF), // 5 %
    borderRadius: BorderRadius.zero, // full-screen — no rounded corners
    padding: EdgeInsets.zero,
  );

  static const _sheetLight = GlassConfig(
    blurSigma: 24,
    fill: Color(0xA6FFFFFF), // 65 %
    border: Color(0x1EFFFFFF), // 12 %
    highlight: Color(0x0DFFFFFF), // 5 %
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    padding: EdgeInsets.fromLTRB(0, 8, 0, 0), // 8 px drag-handle clearance
  );

  // ── High quality — Dark theme ────────────────────────────────────────────
  //
  // Targets iOS 17/18 `.ultraThinMaterial` in dark mode:
  //   fill   ~8 % white   (0x14 = 20/255 ≈ 8 %)
  //   border ~12 % white  (top-edge highlight is more visible on dark surfaces)
  //   blur   14 px logical

  static const _cardDark = GlassConfig(
    blurSigma: 14,
    fill: Color(0x14FFFFFF), // 8 %  — iOS ultraThinMaterial dark
    border: Color(0x1FFFFFFF), // 12 % — top-edge highlight
    highlight: Color(0x0DFFFFFF), // 5 %  — diagonal sheen
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  static const _miniPlayerDark = GlassConfig(
    blurSigma: 24,
    fill: Color(0x16FFFFFF), // 9 %
    border: Color(0x21FFFFFF), // 13 %
    highlight: Color(0x0DFFFFFF), // 5 %
    borderRadius: BorderRadius.all(Radius.circular(16)),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );

  static const _nowPlayingDark = GlassConfig(
    blurSigma: 26,
    fill: Color(0x10FFFFFF), // 6 %  — very thin to let artwork breathe
    border: Color(0x16FFFFFF), // 9 %
    highlight: Color(0x0AFFFFFF), // 4 %
    borderRadius: BorderRadius.zero, // full-screen — no rounded corners
    padding: EdgeInsets.zero,
  );

  static const _sheetDark = GlassConfig(
    blurSigma: 24,
    fill: Color(0x19FFFFFF), // 10 %
    border: Color(0x16FFFFFF), // 9 %
    highlight: Color(0x0AFFFFFF), // 4 %
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
  );

  // ── Low quality — Light theme ────────────────────────────────────────────
  //
  // Blur halved vs. high; fill boosted to compensate for reduced translucency.

  static const _cardLowLight = GlassConfig(
    blurSigma: 8,
    fill: Color(0xA0FFFFFF), // 63 % — boosted to compensate for less blur
    border: Color(0x11FFFFFF), // 7 %
    highlight: Color(0x0AFFFFFF), // 4 %
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  static const _miniPlayerLowLight = GlassConfig(
    blurSigma: 12,
    fill: Color(0xB0FFFFFF), // 69 %
    border: Color(0x18FFFFFF), // 10 %
    highlight: Color(0x0AFFFFFF), // 4 %
    borderRadius: BorderRadius.all(Radius.circular(16)),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );

  static const _nowPlayingLowLight = GlassConfig(
    blurSigma: 14,
    fill: Color(0x82FFFFFF), // 51 %
    border: Color(0x16FFFFFF), // 9 %
    highlight: Color(0x0AFFFFFF), // 4 %
    borderRadius: BorderRadius.zero,
    padding: EdgeInsets.zero,
  );

  static const _sheetLowLight = GlassConfig(
    blurSigma: 14,
    fill: Color(0xB5FFFFFF), // 71 %
    border: Color(0x16FFFFFF), // 9 %
    highlight: Color(0x0AFFFFFF), // 4 %
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
  );

  // ── Low quality — Dark theme ─────────────────────────────────────────────

  static const _cardLowDark = GlassConfig(
    blurSigma: 8,
    fill: Color(0x1EFFFFFF), // 12 % — boosted vs. high-quality 8 %
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
  );

  // ── Off — flat tint, no BackdropFilter ───────────────────────────────────
  //
  // [blurSigma] == 0 triggers the fast path in GlassCard (no compositing layer).
  // Fill colours match iOS system background tokens:
  //   light → systemGroupedBackground  (#F2F2F7)
  //   dark  → secondarySystemBackground (#1C1C1E)

  static const _cardOffLight = GlassConfig(
    blurSigma: 0,
    fill: Color(0xE6F2F2F7), // 90 % systemGroupedBackground
    border: Colors.transparent,
    highlight: Colors.transparent,
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  static const _cardOffDark = GlassConfig(
    blurSigma: 0,
    fill: Color(0xE61C1C1E), // 90 % secondarySystemBackground dark
    border: Colors.transparent,
    highlight: Colors.transparent,
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  static const _sheetOffLight = GlassConfig(
    blurSigma: 0,
    fill: Color(0xFFF5F5F7), // systemBackground light (opaque)
    border: Colors.transparent,
    highlight: Colors.transparent,
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
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
