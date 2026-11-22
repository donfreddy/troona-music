import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics.dart';
import 'package:troona/shared/widgets/app_button.dart';

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

  /// Where to seek for a line: its time, corrected by the offsets.
  final Duration Function(LyricLine line) seekTargetOf;
  final ValueChanged<Duration> onSeek;

  const SyncedLyricsView({
    super.key,
    required this.lyrics,
    required this.activeLine,
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

  bool get _hasIntro {
    final lines = widget.lyrics.lines;
    return lines.isNotEmpty && lines.first.at >= SyncedLyricsView.introDots;
  }

  @override
  void initState() {
    super.initState();
    _keys = _keysFor(widget.lyrics);
    widget.activeLine.addListener(_onLine);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLine(true));
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLine(true));
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
                child: SingleChildScrollView(
                  controller: _scroll,
                  // Room at the end for the options button above the lines.
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.xl2,
                    end: AppSpacing.xl2 + 28,
                  ),
                  child: ValueListenableBuilder<int>(
                    valueListenable: widget.activeLine,
                    builder: (context, active, _) => Column(
                      key: _column,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: _height * SyncedLyricsView.anchor),
                        if (_hasIntro)
                          _InstrumentalDots(key: _intro, active: active < 0),
                        for (var i = 0; i < lines.length; i++)
                          KeyedSubtree(
                            key: _keys[i],
                            child: lines[i].isPause
                                ? _InstrumentalDots(active: active == i)
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

  static double alphaAt(int distance) => switch (distance) {
    0 => 1,
    1 || 2 => 0.45,
    3 || 4 => 0.3,
    _ => 0.2,
  };

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
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
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: alphaAt(distance)),
            duration: still ? Duration.zero : duration,
            curve: Curves.easeOutCubic,
            builder: (context, alpha, child) => TweenAnimationBuilder<double>(
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
                    color: Colors.white.withValues(alpha: alpha),
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

/// Three dots for a passage with no singing; lit while it plays.
class _InstrumentalDots extends StatelessWidget {
  final bool active;

  const _InstrumentalDots({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    final alpha = active ? 1.0 : 0.3;
    return Semantics(
      label: context.l10n.lyricsInstrumental,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 300),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: alpha),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
