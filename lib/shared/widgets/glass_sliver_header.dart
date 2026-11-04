import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show OverScrollHeaderStretchConfiguration;
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/theme/components/glass_filter.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';

/// The header of every scrolling page: content scrolls under it, edge to
/// edge, and it collapses into a glass bar that keeps the back button, the
/// compact title and the actions.
///
/// Expanded, it shows [expanded] (a large title, an album hero) below the
/// navigation row, on no glass at all. Scrolling moves [expanded] up like
/// content, fading it out, and the row's bottom edge cuts it; the compact
/// [title] fades in. Once collapsed, the following slivers pass under the
/// bar, which blurs them with [GlassTheme.bar].
///
/// Blur cost: the filter keeps one sigma and is only switched on once the
/// header is collapsed, when content starts to pass under it; the tint
/// alone follows the scroll. Before that, only the page background is
/// behind it, and a blur of it would not show.
class GlassSliverHeader extends StatelessWidget {
  /// Compact title, shown in the bar once collapsed. Null with no [leading]
  /// and no [actions]: no navigation row (Search, whose field is the bar).
  final String? title;

  /// Back button of a pushed page ([AppBackButton]).
  final Widget? leading;
  final List<Widget> actions;

  /// What the expanded header shows below the navigation row. It is laid
  /// out at its full height and slides up under the row on scroll.
  final Widget? expanded;

  /// Height of [expanded] at the default font size.
  final double expandedHeight;

  /// Part of [expandedHeight] taken by text: it grows with the font size.
  final double expandedTextHeight;

  /// Painted edge to edge behind the whole expanded header, status bar
  /// included (an artist photo). It scrolls with the content, so its bottom
  /// stays on the header's edge, and fades out.
  final Widget? background;

  /// Stays below the navigation row once collapsed (Library filter, Search
  /// field). Fixed height: its text is capped at [AppLayout.maxTextScale].
  final Widget? pinnedBottom;
  final double pinnedBottomHeight;

  /// Overscroll at the top stretches the header instead of moving it down.
  final bool stretch;

  /// A scroll that stops halfway through the collapse finishes it, up or
  /// down, so the title is never left cut in two (iOS large titles). The
  /// header must be the scroll view's first sliver.
  final bool snap;

  /// How much faster than the collapse [expanded] fades out. A hero fades
  /// with it (1): its cover and buttons stay in sight while they scroll
  /// away, with no empty band under the bar. A large title, cut by the
  /// row's edge, is gone a little sooner.
  final double expandedFade;

  const GlassSliverHeader({
    super.key,
    this.title,
    this.leading,
    this.actions = const [],
    this.expanded,
    this.expandedHeight = 0,
    this.expandedTextHeight = 0,
    this.background,
    this.pinnedBottom,
    this.pinnedBottomHeight = 0,
    this.stretch = false,
    this.snap = false,
    this.expandedFade = 1,
  });

  /// iOS large title: [title] big at the top of the page, which slides
  /// under the bar and comes back in it, small.
  GlassSliverHeader.largeTitle({
    super.key,
    required String this.title,
    this.leading,
    this.actions = const [],
    this.pinnedBottom,
    this.pinnedBottomHeight = 0,
  }) : expanded = _LargeTitle(title),
       expandedHeight = largeTitleHeight,
       expandedTextHeight = _LargeTitle.lineHeight,
       background = null,
       stretch = false,
       snap = true,
       expandedFade = 1.6;

  /// Height of the navigation row, below the status bar.
  static const double navBarHeight = 44;

  /// Height of the large title's area at the default font size.
  static const double largeTitleHeight = 86;

  /// Height below the header over which its glass fades out, instead of
  /// stopping on a line.
  static const double softEdge = 24;

  /// Bottom of the navigation row, from the top of the screen: what a
  /// [RefreshIndicator] over the page takes as its edge offset.
  static double navBarBottom(BuildContext context) =>
      MediaQuery.paddingOf(context).top + navBarHeight;

  /// Height of an expanded part of [height] at the default font size, of
  /// which [textHeight] is text, at the phone's font size.
  static double expandedExtentOf(
    BuildContext context,
    double height,
    double textHeight,
  ) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return height + math.max(0, textScale - 1) * textHeight;
  }

  @override
  Widget build(BuildContext context) {
    final hasNavBar = title != null || leading != null || actions.isNotEmpty;
    final expandedExtent = expandedExtentOf(
      context,
      expandedHeight,
      expandedTextHeight,
    );
    final header = SliverPersistentHeader(
      pinned: true,
      delegate: _GlassHeaderDelegate(
        header: this,
        topPadding: MediaQuery.paddingOf(context).top,
        navHeight: hasNavBar ? navBarHeight : 0,
        expandedExtent: expandedExtent,
      ),
    );
    if (!snap || expandedExtent <= 0) return header;
    return _SnapToEdges(range: expandedExtent, child: header);
  }
}

/// Finishes a collapse left halfway once the scroll stops and no finger is
/// on the screen: the header's collapse spans the first [range] pixels of
/// the scroll view.
class _SnapToEdges extends StatefulWidget {
  final double range;
  final Widget child;

  const _SnapToEdges({required this.range, required this.child});

  @override
  State<_SnapToEdges> createState() => _SnapToEdgesState();
}

class _SnapToEdgesState extends State<_SnapToEdges> {
  ScrollPosition? _position;

  /// Fingers on the screen. A finger that stops a fling ends the scroll
  /// (a hold is no scroll) but must not be snapped under; its release,
  /// with no scroll after it, must be.
  int _pointers = 0;

  @override
  void initState() {
    super.initState();
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
  }

  void _onPointer(PointerEvent event) {
    if (event is PointerDownEvent) {
      _pointers++;
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _pointers = math.max(0, _pointers - 1);
      if (_pointers == 0) scheduleMicrotask(_snap);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position == _position) return;
    _position?.isScrollingNotifier.removeListener(_onScrolling);
    _position = position?..isScrollingNotifier.addListener(_onScrolling);
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    _position?.isScrollingNotifier.removeListener(_onScrolling);
    super.dispose();
  }

  // Called from within ScrollPosition.beginActivity: starting the snap
  // there would cut the ending scroll short (no ScrollEndNotification).
  void _onScrolling() => scheduleMicrotask(_snap);

  void _snap() {
    final position = _position;
    if (!mounted || position == null || _pointers > 0) return;
    if (position.isScrollingNotifier.value) return;
    if (!position.hasPixels || !position.hasContentDimensions) return;
    // Content too short to collapse the header fully: a snap would pull
    // the end of it out of reach.
    final range = widget.range;
    if (position.maxScrollExtent < range) return;
    final pixels = position.pixels;
    if (pixels <= 0 || pixels >= range) return;
    final target = pixels < range / 2 ? 0.0 : range;
    if ((target - pixels).abs() < 1) return;
    position.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _GlassHeaderDelegate extends SliverPersistentHeaderDelegate {
  final GlassSliverHeader header;
  final double topPadding;
  final double navHeight;

  /// Height of [GlassSliverHeader.expanded] at the phone's font size.
  final double expandedExtent;

  _GlassHeaderDelegate({
    required this.header,
    required this.topPadding,
    required this.navHeight,
    required this.expandedExtent,
  });

  /// Scroll over which a header that cannot collapse (Search) takes its
  /// glass, once content passes under it.
  static const _glassFadeDistance = 24.0;

  @override
  double get minExtent => topPadding + navHeight + header.pinnedBottomHeight;

  @override
  double get maxExtent => minExtent + expandedExtent;

  @override
  OverScrollHeaderStretchConfiguration? get stretchConfiguration =>
      header.stretch ? OverScrollHeaderStretchConfiguration() : null;

  @override
  bool shouldRebuild(_GlassHeaderDelegate old) =>
      old.header != header ||
      old.topPadding != topPadding ||
      old.navHeight != navHeight ||
      old.expandedExtent != expandedExtent;

  /// 0 expanded, 1 collapsed. A header that cannot collapse is "collapsed"
  /// once content scrolls under it.
  double collapseOf(double shrinkOffset) {
    final range = maxExtent - minExtent;
    if (range <= 0) {
      return (shrinkOffset / _glassFadeDistance).clamp(0.0, 1.0);
    }
    return (shrinkOffset / range).clamp(0.0, 1.0);
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final collapse = collapseOf(shrinkOffset);
    final glass = GlassTheme.bar(context);
    final expandedTop = topPadding + navHeight;
    final background = header.background;
    final expanded = header.expanded;
    final pinnedBottom = header.pinnedBottom;

    // Keyed: a background that comes later (a photo once loaded) must not
    // shift the other layers and rebuild their state.
    final body = Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        // ── Edge-to-edge background: scrolls with the content ───────────
        // At half speed (parallax), the header's edge would cut it short.
        if (background != null)
          Positioned(
            key: const ValueKey('background'),
            // Stretched (overscroll, shrinkOffset 0): fills the taller box.
            top: shrinkOffset > 0 ? -shrinkOffset : 0,
            left: 0,
            right: 0,
            height: shrinkOffset > 0 ? maxExtent : null,
            bottom: shrinkOffset > 0 ? null : 0,
            child: _Fade(opacity: 1 - collapse, child: background),
          ),

        // ── Expanded content: scrolls up under the navigation row ───────
        if (expanded != null && expandedExtent > 0)
          Positioned(
            key: const ValueKey('expanded'),
            top: expandedTop,
            left: 0,
            right: 0,
            bottom: header.pinnedBottomHeight,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.bottomCenter,
                minHeight: expandedExtent,
                maxHeight: expandedExtent,
                child: _Fade(
                  opacity: 1 - collapse * header.expandedFade,
                  child: expanded,
                ),
              ),
            ),
          ),

        // ── Navigation row: back button, compact title, actions ─────────
        if (navHeight > 0)
          Positioned(
            key: const ValueKey('nav'),
            top: topPadding,
            left: 0,
            right: 0,
            height: navHeight,
            child: _NavRow(
              leading: header.leading,
              title: header.title,
              titleOpacity: collapse,
              actions: header.actions,
            ),
          ),

        // ── Pinned bottom: filter, search field ─────────────────────────
        if (pinnedBottom != null)
          Positioned(
            key: const ValueKey('pinnedBottom'),
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: 0,
            height: header.pinnedBottomHeight,
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: AppLayout.maxTextScale,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: pinnedBottom,
                ),
              ),
            ),
          ),
      ],
    );

    // The glass reaches [softEdge] below the header and fades out there,
    // blur and tint together: no line where the bar ends (iOS scroll edge).
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: -GlassSliverHeader.softEdge,
          child: IgnorePointer(
            child: _GlassLayer(
              glass: glass,
              tint: collapse,
              // Content passes under a pinned header only once it is
              // collapsed (or, for one that cannot collapse, scrolled).
              blur: maxExtent == minExtent
                  ? collapse > 0
                  : shrinkOffset >= maxExtent - minExtent,
            ),
          ),
        ),
        body,
      ],
    );
  }
}

/// The bar's glass, [GlassSliverHeader.softEdge] taller than the header:
/// the blur stops at the header's edge, and the tint carries on below it,
/// fading to nothing, so the bar has no line.
///
/// The blur cannot fade itself: a [BackdropFilter] under a [ShaderMask]
/// reads the mask's empty layer, not the page, and blurs nothing (checked
/// on Impeller).
class _GlassLayer extends StatelessWidget {
  final GlassConfig glass;

  /// Share of the bar's tint, 0 to 1.
  final double tint;
  final bool blur;

  const _GlassLayer({
    required this.glass,
    required this.tint,
    required this.blur,
  });

  @override
  Widget build(BuildContext context) {
    final fill = Color.lerp(Colors.transparent, glass.fill, tint)!;
    final bar = ColoredBox(color: fill);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: GlassSliverHeader.softEdge,
          child: RepaintBoundary(
            child: ClipRect(
              child: glass.blurSigma == 0
                  ? bar
                  : BackdropFilter(
                      // One sigma: a filter that changes every frame is
                      // rebuilt every frame, and small sigmas are the
                      // costliest to blur.
                      enabled: blur,
                      filter: GlassFilter.of(
                        glass.blurSigma,
                        saturation: glass.saturation,
                      ),
                      child: bar,
                    ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: GlassSliverHeader.softEdge,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [fill, fill.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Fades [child] without repainting it: the [RepaintBoundary] keeps its
/// picture (shadows, covers) while only the opacity changes on scroll.
class _Fade extends StatelessWidget {
  final double opacity;
  final Widget child;

  const _Fade({required this.opacity, required this.child});

  @override
  Widget build(BuildContext context) {
    final o = opacity.clamp(0.0, 1.0);
    return Opacity(
      opacity: o,
      // Hidden content takes no tap.
      child: IgnorePointer(
        ignoring: o == 0,
        child: RepaintBoundary(child: child),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final Widget? leading;
  final String? title;
  final double titleOpacity;
  final List<Widget> actions;

  const _NavRow({
    required this.leading,
    required this.title,
    required this.titleOpacity,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    // Fixed-height chrome: the font size is followed up to the layout cap.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: AppLayout.maxTextScale,
      child: Padding(
        // A back button sits [AppSpacing.sm] from the edge; a root page's
        // actions line up with its content.
        padding: EdgeInsets.only(
          left: AppSpacing.sm,
          right: leading == null ? AppSpacing.lg : AppSpacing.sm,
        ),
        child: NavigationToolbar(
          // Its own width: [AppBackButton] centres itself and would take
          // the whole row, leaving the title no room.
          leading: leading == null ? null : IntrinsicWidth(child: leading),
          middle: title == null
              ? null
              : Opacity(
                  opacity: titleOpacity,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: context.colors.labelPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
          trailing: actions.isEmpty
              ? null
              : Row(mainAxisSize: MainAxisSize.min, children: actions),
          middleSpacing: AppSpacing.sm,
        ),
      ),
    );
  }
}

class _LargeTitle extends StatelessWidget {
  final String title;

  const _LargeTitle(this.title);

  /// Line height of the large title (34 x 1.21) at the default font size.
  static const double lineHeight = 41;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        // A long title in a large font shrinks to the line instead of
        // being cut: it stays whole, as large as the line allows.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.bottomLeft,
          child: Text(
            title,
            maxLines: 1,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: context.colors.labelPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
