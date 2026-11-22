import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/theme/semantic/palette_ink.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/app_button.dart';
import 'package:troona/shared/widgets/palette_ink_scope.dart';

/// Synced lyrics, the line being sung lit and held at [anchor] of the
/// height.
///
/// Every line is built at once (a song rarely has a hundred): the place of
/// each is known, which a lazy list could not tell before building it. All
/// lines are laid out at one font size; the line being sung differs by a
/// scale and its colour's alpha, never by its font, which would wrap the
/// text again on every frame. Only [activeLine] rebuilds them.
///
/// A finger moving the list stops the follow, and a pill offers to come
/// back; it comes back by itself after [resumeAfter], or on a tap on a
/// line, which seeks there.
class SyncedLyricsView extends StatefulWidget {
  final SyncedLyrics lyrics;
  final ValueListenable<int> activeLine;

  /// The playback position, for the dots of a passage with no singing:
  /// they fill as it goes. Nothing else listens to it.
  final ValueListenable<PlaybackProgress> position;

  /// Where to seek for a line: its time, corrected by the offsets.
  final Duration Function(LyricLine line) seekTargetOf;
  final ValueChanged<Duration> onSeek;

  const SyncedLyricsView({
    super.key,
    required this.lyrics,
    required this.activeLine,
    required this.position,
    required this.seekTargetOf,
    required this.onSeek,
  });

  /// Where the line being sung sits, as a share of the height: one reads
  /// what comes more than what is gone.
  static const anchor = 0.35;

  static const resumeAfter = Duration(seconds: 4);

  /// An intro at least this long shows the instrumental dots first.
  static const introDots = Duration(seconds: 4);

  static const fontSize = 26.0;

  @override
  State<SyncedLyricsView> createState() => _SyncedLyricsViewState();
}

class _SyncedLyricsViewState extends State<SyncedLyricsView> {
  final _scroll = ScrollController();
  final _column = GlobalKey();
  late List<GlobalKey> _keys;
  final _intro = GlobalKey();
  bool _following = true;
  Timer? _resume;
  double _height = 0;

  /// Whether the list is where the line sung puts it. The first frame
  /// lays the lines out from their top; shown then, the song's first words
  /// would flash before the jump to the line sung.
  bool _placed = false;

  void _place() {
    if (!mounted) return;
    _scrollToLine(true);
    if (!_placed) setState(() => _placed = true);
  }

  /// When the passage with no singing at [index] (-1: the intro) starts
  /// and ends, in playback time.
  (Duration, Duration) _pauseSpan(int index) {
    final lines = widget.lyrics.lines;
    final start = index < 0 ? Duration.zero : widget.seekTargetOf(lines[index]);
    final next = index + 1;
    final end = next < lines.length
        ? widget.seekTargetOf(lines[next])
        : start + SyncedLyricsView.introDots;
    return (start, end);
  }

  bool get _hasIntro {
    final lines = widget.lyrics.lines;
    return lines.isNotEmpty && lines.first.at >= SyncedLyricsView.introDots;
  }

  @override
  void initState() {
    super.initState();
    _keys = _keysFor(widget.lyrics);
    widget.activeLine.addListener(_onLine);
    WidgetsBinding.instance.addPostFrameCallback((_) => _place());
  }

  @override
  void didUpdateWidget(SyncedLyricsView old) {
    super.didUpdateWidget(old);
    if (old.activeLine != widget.activeLine) {
      old.activeLine.removeListener(_onLine);
      widget.activeLine.addListener(_onLine);
    }
    if (old.lyrics != widget.lyrics) {
      _keys = _keysFor(widget.lyrics);
      _following = true;
      _resume?.cancel();
      _placed = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _place());
    }
  }

  @override
  void dispose() {
    widget.activeLine.removeListener(_onLine);
    _resume?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  static List<GlobalKey> _keysFor(SyncedLyrics lyrics) => [
    for (final _ in lyrics.lines) GlobalKey(),
  ];

  void _onLine() {
    if (_following) _scrollToLine(false);
  }

  /// Brings the line being sung to [SyncedLyricsView.anchor].
  void _scrollToLine(bool jump) {
    if (!mounted || !_scroll.hasClients) return;
    final index = widget.activeLine.value;
    final key = index >= 0 && index < _keys.length
        ? _keys[index]
        : (_hasIntro ? _intro : null);
    final top = key == null ? 0.0 : _topOf(key);
    if (top == null) return;
    final position = _scroll.position;
    final target = (top - _height * SyncedLyricsView.anchor).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((target - position.pixels).abs() < 0.5) return;
    final still = MediaQuery.disableAnimationsOf(context);
    if (jump) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(
        target,
        duration: Duration(milliseconds: still ? 150 : 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// The top of the widget [key] holds, in the column.
  double? _topOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    final column = _column.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || column == null || !box.attached) return null;
    return box.localToGlobal(Offset.zero, ancestor: column).dy;
  }

  bool _onScroll(ScrollNotification n) {
    if (n is ScrollStartNotification && n.dragDetails != null) {
      _resume?.cancel();
      if (_following) setState(() => _following = false);
    } else if (n is ScrollEndNotification && !_following) {
      _resume?.cancel();
      _resume = Timer(SyncedLyricsView.resumeAfter, _follow);
    }
    return false;
  }

  void _follow() {
    _resume?.cancel();
    if (!mounted) return;
    setState(() => _following = true);
    _scrollToLine(false);
  }

  void _tap(LyricLine line) {
    AppHaptics.selectionClick();
    widget.onSeek(widget.seekTargetOf(line));
    _follow();
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.lyrics.lines;
    return LayoutBuilder(
      builder: (context, box) {
        _height = box.maxHeight;
        return Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: ShaderMask(
                // Lines melt in at the top and out at the bottom.
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: [0, 0.1, 0.85, 1],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                // Hidden at once (new lyrics still stand at the old
                // place for a frame), shown in a fade.
                child: AnimatedOpacity(
                  opacity: _placed ? 1 : 0,
                  duration: _placed && !MediaQuery.disableAnimationsOf(context)
                      ? const Duration(milliseconds: 180)
                      : Duration.zero,
                  child: SingleChildScrollView(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl2,
                    ),
                    child: ValueListenableBuilder<int>(
                      valueListenable: widget.activeLine,
                      builder: (context, active, _) => Column(
                        key: _column,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: _height * SyncedLyricsView.anchor),
                          if (_hasIntro)
                            _InstrumentalDots(
                              key: _intro,
                              active: active < 0,
                              position: widget.position,
                              span: _pauseSpan(-1),
                            ),
                          for (var i = 0; i < lines.length; i++)
                            KeyedSubtree(
                              key: _keys[i],
                              child: lines[i].isPause
                                  ? _InstrumentalDots(
                                      active: active == i,
                                      position: widget.position,
                                      span: _pauseSpan(i),
                                    )
                                  : _LyricLineTile(
                                      line: lines[i],
                                      distance: active < 0
                                          ? i + 1
                                          : (i - active).abs(),
                                      target: widget.seekTargetOf(lines[i]),
                                      onTap: () => _tap(lines[i]),
                                    ),
                            ),
                          SizedBox(
                            height: _height * (1 - SyncedLyricsView.anchor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.sm,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _following
                      ? const SizedBox.shrink()
                      : AppButton.secondary(
                          context.l10n.lyricsBackToLine,
                          size: AppButtonSize.small,
                          onPressed: _follow,
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One line: lit when sung ([distance] 0), fainter the further it is.
class _LyricLineTile extends StatelessWidget {
  final LyricLine line;
  final int distance;
  final Duration target;
  final VoidCallback onTap;

  const _LyricLineTile({
    required this.line,
    required this.distance,
    required this.target,
    required this.onTap,
  });

  /// The line sung in white, the two around it at [PaletteInk.near], the
  /// rest at [PaletteInk.far]: tints of the glow, faint as each may be.
  static Color colorAt(int distance, PaletteInk ink) => switch (distance) {
    0 => ink.primary,
    1 || 2 => ink.near,
    _ => ink.far,
  };

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final color = colorAt(distance, PaletteInkScope.of(context));
    final scale = distance == 0 || still ? 1.0 : 0.94;
    const duration = Duration(milliseconds: 300);
    return Semantics(
      button: true,
      hint: context.l10n.lyricsGoTo(target.toMMSS()),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: color),
            duration: still ? Duration.zero : duration,
            curve: Curves.easeOutCubic,
            builder: (context, color, child) => TweenAnimationBuilder<double>(
              tween: Tween(end: scale),
              duration: duration,
              curve: Curves.easeOutCubic,
              builder: (context, scale, _) => Transform.scale(
                scale: scale,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  line.text,
                  style: TextStyle(
                    fontSize: SyncedLyricsView.fontSize,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    // Through the colour, never an Opacity: no layer per
                    // line.
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Three dots for a passage with no singing. While it plays they fill
/// one after the other, the last as the singing comes back: one sees how
/// long is left. Dim before and after. Painted from [position] alone, so
/// its ticks rebuild nothing; with reduced motion they are simply lit.
class _InstrumentalDots extends StatelessWidget {
  final bool active;
  final ValueListenable<PlaybackProgress> position;

  /// When the passage starts and ends, in playback time.
  final (Duration, Duration) span;

  const _InstrumentalDots({
    super.key,
    required this.active,
    required this.position,
    required this.span,
  });

  @override
  Widget build(BuildContext context) {
    final ink = PaletteInkScope.of(context);
    return Semantics(
      label: context.l10n.lyricsInstrumental,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: RepaintBoundary(
            child: CustomPaint(
              size: const Size(_DotsPainter.width, _DotsPainter.dot),
              painter: _DotsPainter(
                active: active,
                position: position,
                span: span,
                still: MediaQuery.disableAnimationsOf(context),
                rtl: Directionality.of(context) == TextDirection.rtl,
                unlit: ink.far,
                lit: ink.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  final bool active;
  final ValueListenable<PlaybackProgress> position;
  final (Duration, Duration) span;
  final bool still;
  final bool rtl;
  final Color unlit;
  final Color lit;

  _DotsPainter({
    required this.active,
    required this.position,
    required this.span,
    required this.still,
    required this.rtl,
    required this.unlit,
    required this.lit,
  }) : super(repaint: active && !still ? position : null);

  static const double dot = 10;
  static const double gap = 8;
  static const double width = 3 * dot + 2 * gap;

  /// How lit each of the three dots is (0 to 1) at [progress] of the
  /// passage: one after the other, each over a third of it.
  @visibleForTesting
  static List<double> fill(double progress) => [
    for (var i = 0; i < 3; i++) (progress * 3 - i).clamp(0.0, 1.0),
  ];

  double get _progress {
    if (!active) return 0;
    if (still) return 1;
    final (start, end) = span;
    final length = (end - start).inMicroseconds;
    if (length <= 0) return 1;
    return ((position.value.position - start).inMicroseconds / length).clamp(
      0.0,
      1.0,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final filled = fill(_progress);
    for (var i = 0; i < 3; i++) {
      final slot = rtl ? 2 - i : i;
      canvas.drawCircle(
        Offset(slot * (dot + gap) + dot / 2, size.height / 2),
        dot / 2,
        Paint()..color = Color.lerp(unlit, lit, filled[i])!,
      );
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) =>
      old.active != active ||
      old.span != span ||
      old.still != still ||
      old.rtl != rtl ||
      old.unlit != unlit ||
      old.lit != lit ||
      old.position != position;
}
