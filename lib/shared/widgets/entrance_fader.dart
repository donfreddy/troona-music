import 'dart:async';
import 'package:flutter/material.dart';

class EntranceFader extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  /// False shows the child as the entrance ends, with no timer. Read once,
  /// when first built: the same transitions wrap the child either way, so
  /// a later rebuild neither replays nor remounts it.
  final bool play;

  const EntranceFader({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 280),
    this.offset = const Offset(0, 0.15),
    this.play = true,
  });

  /// Utility constructor for easily scaling animations based on an index.
  factory EntranceFader.staggered({
    Key? key,
    required Widget child,
    required int index,
    int stepMs = 22,
    Duration duration = const Duration(milliseconds: 280),
    double slideY = 0.15,
    int maxDelayMs = 120,
    bool play = true,
  }) {
    final delayMs = (index * stepMs).clamp(0, maxDelayMs);
    return EntranceFader(
      key: key ?? child.key,
      delay: Duration(milliseconds: delayMs),
      duration: duration,
      offset: Offset(0, slideY),
      play: play,
      child: child,
    );
  }

  @override
  State<EntranceFader> createState() => _EntranceFaderState();
}

class _EntranceFaderState extends State<EntranceFader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _slideAnimation = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (!widget.play) {
      _controller.value = 1;
    } else if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
