# Theme and glass audit

Scope: colours, glassmorphism and their GPU cost. Read from the code on branch `chore/store-ready`; contrast ratios computed (WCAG 2.1 relative luminance); no on-device profiling yet.

Vocabulary used by the project, for readers coming from the brief: state is `flutter_bloc` (not Riverpod); the glass component is `GlassTheme` / `GlassConfig` / `GlassCard` in `lib/core/theme/components/` and `lib/shared/widgets/` (there is no `TroonaGlass`); colours are the `AppColors` `ThemeExtension` (the brand colour is the `accent` token, not `primaryColor`).

## Verdict

Real glass, not a flat translucent layer: every chrome surface (tab bar, collapsing header, sheets, Now Playing lens and dock) uses a true `BackdropFilter`, isolated in a `RepaintBoundary`, over a glowing background. The token hierarchy and the quality tiers are sound.

It is not yet iOS 18 material, for one main reason: the blur has **no saturation boost**. iOS materials saturate what is behind them before blurring; here the blur alone turns colours grey, and with a 3 to 4 % white fill on a mostly black page, the glass only reads where the top glow sits.

Performance is mostly under control. Two places break the two-blur budget while scrolling, and the "low" tier lowers the blur radius, which saves little GPU time.

## What works

- **Three token levels**: primitives (`ColorPrimitives`), semantic (`AppColors`, a `ThemeExtension` with `lerp`), components (`GlassConfig` per surface and tier).
- **Quality tiers with a real fast path**: `off` skips `BackdropFilter` entirely (`blurSigma == 0`), every call site honours it.
- **A user setting already exists**: Settings, glass quality `auto / high / low / off` (`SettingsCubit.setGlassQuality`, `GlassTheme.overrideQuality`).
- **Automatic tier at start-up** (`GlassTier.detect`): RAM under 3 GB gives `off`, under 6 GB or Android below 10 gives `low`, otherwise `high`; "remove animations" gives `off`; iOS is `high`.
- **Repaint discipline**: the playback clock goes through a `ValueListenable` outside the bloc state; `DynamicBackground` stays still between tracks (380 ms cross-fade on change); the header blur grows with the collapse and is absent when expanded; the lens clamps its sigma.
- **The Now Playing lens** is the best surface: annulus clip, radial sheen, light-catching rim gradient, inner hairline. That is the "polished glass" look the rest should match.
- **Brand contrast is good**: accent `#B79CFF` on black 9.2:1, text on accent 8.5:1, secondary labels on black 6.4:1.

## Findings

| # | Severity | Finding | Where |
|---|---|---|---|
| G1 | High (perf) | **Three blurs while scrolling** on album and artist pages when online extras are on: collapsed header blur, tab bar (mini player), and the wiki or bio `GlassCard`, which blurs by default (sigma 20). Every scroll frame re-runs all three. | `album_wiki_section.dart:32`, `artist_bio_section.dart:38`, `glass_card.dart:32` |
| G2 | High (a11y) | **Secondary text fails contrast at the top of palette pages.** Backgrounds are set by HSL lightness (0.25 / 0.15), which is not perceptual: a yellow cover comes out five times brighter than a blue one. Secondary labels over the top glow: blue 5.1:1, red 4.5:1, cyan 3.1:1, green 3.0:1, yellow 2.8:1. The default ambient glow (no artwork) gives 2.5:1. Large titles stay above 3:1. | `track_palette_cubit.dart` `adaptBg`, `ColorPrimitives.ambientTop` |
| G3 | Medium (look) | **No saturation in the glass.** iOS materials boost saturation behind the blur; here colours wash out to grey. | the 8 `ImageFilter.blur` call sites |
| G4 | Medium (perf) | **The low tier lowers sigma, which barely saves GPU.** Both Skia and Impeller downsample large blurs, so cost is driven by the number and area of blurred surfaces and by how many frames are drawn, not by sigma. Low tier looks worse for about the same cost. To confirm with the profiler. | `GlassTheme` low presets |
| G5 | Medium | **Blur keeps running while music plays.** The playback clock repaints the mini player about 5 times per second (just_audio's position stream), and each frame re-runs every visible backdrop filter. Fine on the tab bar alone; it adds up with G1. | shell, Now Playing |
| G6 | Low (look, perf) | **Glass border: four clipped strokes, two invisible.** `_GlassBorderPainter` draws the rounded rect four times (save, clip, draw, restore); the bottom and right strokes are `highlight * 0.05`, about 0.3 % alpha. No "double stroke" (outer light plus inner shade) either. | `glass_card.dart` |
| G7 | Low | **Stale documentation, and my own wrong answer.** The `GlassTheme` doc describes a pixel-ratio and screen-size heuristic; the real detection is by RAM and Android version (above). I repeated the stale doc in the What's new answer; the table above is correct. Also: low-tier comments quoting old percentages; `_miniPlayerLowDark.highlight` is alpha 0 while its comment says 3 %; `DynamicBackground` says palette work is off the UI isolate, while `TrackPaletteCubit` quantises on it (64 x 64, a few ms). | `glass_theme.dart`, `dynamic_background.dart` |
| G8 | Low | **Dead light theme.** The app is dark only, yet `AppColors.light` and every light glass preset in `glass_theme.dart` are kept and tuned. | `app_theme.dart`, `glass_theme.dart` |
| G9 | Low | **Tier detection by RAM only.** A good proxy, not a GPU measure: a 6 GB phone with a weak GPU gets `high`. | `glass_tier.dart` |

Not findings, deliberately: **noise grain** is not part of iOS 18 materials and Flutter already dithers gradients, so banding is not a problem to solve with grain; optional, cheap, low value. **Light refraction** is iOS 26 "Liquid Glass", not iOS 18; it needs a fragment shader on the backdrop (Impeller only) and is the most expensive effect possible here. Not recommended.

## Fixes

### F1. One glass filter, with saturation (G3)

Every surface builds its own `ImageFilter.blur`. One helper keeps them identical and adds the iOS saturation pass. Colour matrices and blur are both linear, so the order does not matter; the extra cost is one colour pass, to measure.

```dart
/// Backdrop filter of every glass surface: blur plus the saturation boost of
/// iOS materials, so colours behind the glass stay rich instead of greying.
abstract final class GlassFilter {
  static ImageFilter of(double sigma, {double saturation = 1.6}) =>
      ImageFilter.compose(
        outer: ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: TileMode.clamp,
        ),
        inner: ColorFilter.matrix(_saturate(saturation)),
      );

  static List<double> _saturate(double s) {
    const r = 0.2126, g = 0.7152, b = 0.0722;
    final i = 1 - s;
    return [
      r * i + s, g * i, b * i, 0, 0,
      r * i, g * i + s, b * i, 0, 0,
      r * i, g * i, b * i + s, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }
}
```

### F2. Blur is for chrome, not content (G1)

iOS reserves materials for bars, sheets and overlays; cards inside scrolling content are flat. Make `GlassCard` flat by default and let chrome opt in, which also settles the album and artist pages.

```dart
// GlassCard.build: in-content cards scroll with the page; only chrome blurs.
final cfg = config ?? GlassTheme.card(context).copyWith(blurSigma: 0);
```

Cost: the wiki, bio, search and permission cards lose their frost. Over the dark lower half of a page the blur was barely visible anyway.

### F3. Backgrounds capped by luminance, not lightness (G2)

```dart
/// Darkens [c] until its relative luminance is at most [max], keeping the
/// hue: HSL lightness alone lets a yellow cover come out five times brighter
/// than a blue one, and white text on it unreadable.
Color capLuminance(Color c, double max) {
  var hsl = HSLColor.fromColor(c);
  while (hsl.toColor().computeLuminance() > max && hsl.lightness > .02) {
    hsl = hsl.withLightness(hsl.lightness - .01);
  }
  return hsl.toColor();
}
```

Apply it in `adaptBg` and to the ambient fallback, with the threshold chosen so that the painted glow (8 % towards white, 82 % alpha) stays at or under a luminance of about 0.035: secondary labels then reach 4.5:1. A unit test can compute the painted glow for the six reference hues and assert the ratio. Cost: yellow, green and cyan covers glow less brightly.

### F4. One stroke with a gradient (G6)

```dart
@override
void paint(Canvas canvas, Size size) {
  final rect = Offset.zero & size;
  // Light from above: bright top edge fading down the sides.
  canvas.drawRRect(
    borderRadius.toRRect(rect.deflate(width / 2)),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topColor, topColor.withValues(alpha: 0)],
        stops: const [0, .6],
      ).createShader(rect),
  );
}
```

One draw instead of four clip and draw pairs. For the "double stroke" thickness, a second 0.5 px stroke inset by 1 px in 20 % black gives the inner shade; worth it on the tab bar and sheets only.

### F5. A low tier that removes surfaces (G4, G5)

Redefine the tiers by what blurs rather than by how much:

| Tier | Blurs | Flat |
|---|---|---|
| high | tab bar, header, sheets, lens, dock | content cards |
| low | tab bar, Now Playing lens | header, sheets, dock (more opaque fill) |
| off | nothing | everything |

Same API (`GlassTheme.header(context)` returns sigma 0 on low, and so on), so call sites do not change.

## Recommendations

1. **Measure first, on the slowest tester phone**: `flutter run --profile`, performance overlay, DevTools raster thread. Scroll an album page with bios on, and open Now Playing while playing. Target raster time under 16 ms (8 ms on 120 Hz screens). Without these numbers G4 and G5 stay estimates.
2. **Order**: F2 and F3 first (a real budget break and a real readability failure), then F1 (the biggest visual gain), then F4, then F5 if the measures call for it.
3. **Adaptive auto tier** (after measuring): in `auto` only, watch `SchedulerBinding.instance.addTimingsCallback`; if most frames over a few seconds of scrolling exceed the raster budget, step down one tier and remember it. Catches the weak-GPU phones that RAM misses (G9).
4. **`BackdropGroup`** (Flutter 3.29 and later; this project runs 3.47): put the shell in a `BackdropGroup` and use `BackdropFilter.grouped` for the tab bar and the header, so they share one backdrop read on Impeller. To validate with the profiler, gains depend on the device.
5. **Clean-up with no risk**: fix the stale docs and comments (G7); decide on the light theme (G8): delete it, or keep it as an explicit plan.
