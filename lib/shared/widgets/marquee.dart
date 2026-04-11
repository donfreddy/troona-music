import 'package:flutter/material.dart';

class Marquee extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration scrollDuration;
  final Duration pauseDuration;
  final double fadeWidth;

  const Marquee({
    super.key,
    required this.text,
    this.style,
    this.scrollDuration = const Duration(seconds: 8),
    this.pauseDuration = const Duration(seconds: 2),
    this.fadeWidth = 24.0,
  });

  @override
  State<Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<Marquee> {
  final ScrollController _controller = ScrollController();
  bool _isOverflowing = false;
  bool _isAnimating = false;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback(_checkAndStart);
  }

  @override
  void didUpdateWidget(Marquee old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _isAnimating = false;
      _scrollOffset = 0;
      // Reset position before re-measuring
      if (_controller.hasClients) _controller.jumpTo(0);
      WidgetsBinding.instance.addPostFrameCallback(_checkAndStart);
    }
  }

  @override
  void dispose() {
    _isAnimating = false;
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    final offset = _controller.hasClients ? _controller.offset : 0.0;
    if (offset != _scrollOffset) {
      setState(() => _scrollOffset = offset);
    }
  }

  void _checkAndStart(_) {
    if (!mounted || !_controller.hasClients) return;

    final maxScroll = _controller.position.maxScrollExtent;
    final overflow = maxScroll > 0.5; // threshold to ignore layout inaccuracies

    if (overflow != _isOverflowing) {
      setState(() => _isOverflowing = overflow);
    }

    if (overflow && !_isAnimating) {
      _isAnimating = true;
      _runLoop();
    }
  }

  Future<void> _runLoop() async {
    // Initial pause before starting to scroll
    await Future.delayed(widget.pauseDuration);

    while (mounted && _isAnimating) {
      if (!_controller.hasClients) break;

      final max = _controller.position.maxScrollExtent;
      if (max <= 0) break;

      // Scroll to the end: linear, constant speed like Apple Music
      await _controller.animateTo(
        max,
        duration: widget.scrollDuration,
        curve: Curves.linear,
      );

      if (!mounted || !_isAnimating) break;

      // Pause at the end
      await Future.delayed(widget.pauseDuration);

      if (!mounted || !_isAnimating) break;

      // Instant reset to the beginning
      _controller.jumpTo(0);

      // A short break before setting off again
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Minimum threshold to avoid flashing at jumpTo(0)
    final hasScrolledLeft = _scrollOffset > 2.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return ShaderMask(
          // The gradient only hides the edges when scrolling
          shaderCallback: (bounds) {
            if (!_isOverflowing) {
              // No overflow → no fade
              return const LinearGradient(
                colors: [Colors.white, Colors.white],
              ).createShader(bounds);
            }

            final leftFade = widget.fadeWidth / bounds.width;
            final rightFade = 1 - leftFade;

            if (hasScrolledLeft) {
              // Text currently scrolling → fades on both sides
              return LinearGradient(
                stops: [
                  0,
                  leftFade.clamp(0.0, 0.3),
                  rightFade.clamp(0.7, 1.0),
                  1,
                ],
                colors: const [
                  Colors.transparent,
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
              ).createShader(bounds);
            } else {
              // Initial position → fade only to the right
              return LinearGradient(
                stops: [rightFade.clamp(0.7, 1.0), 1],
                colors: const [Colors.white, Colors.transparent],
              ).createShader(bounds);
            }
          },
          blendMode: BlendMode.dstIn,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _controller,
            physics:
                const NeverScrollableScrollPhysics(), // the user does not scroll
            child: Text(widget.text, style: widget.style, maxLines: 1),
          ),
        );
      },
    );
  }
}

//todo:
// Looping Infini (Seamless) : Au lieu de défiler jusqu'au bout
// et de "sauter" brusquement au début.
// implémenté un système de clonage du texte. Le titre apparaît désormais
// une deuxième fois (séparé par un espace paramétrable).
// Dès que le clone atteint la position de départ, on revient à l'offset 0
// de façon invisible pour l'utilisateur, créant une boucle parfaite et infinie.
