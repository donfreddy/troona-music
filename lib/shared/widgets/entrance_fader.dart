import 'dart:async';
import 'package:flutter/material.dart';

/// Un widget d'animation centralisé qui gère correctement son cycle de vie (mounted).
/// Il résout spécifiquement l'erreur "AnimationController.forward() called after dispose()"
/// causée par flutter_animate dans des SliverLists lorsque l'utilisateur navigue rapidement.
class EntranceFader extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  const EntranceFader({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 280),
    this.offset = const Offset(0, 0.15),
  });

  /// Constructeur utilitaire pour échelonner facilement les animations en fonction d'un index.
  factory EntranceFader.staggered({
    Key? key,
    required Widget child,
    required int index,
    int stepMs = 22,
    Duration duration = const Duration(milliseconds: 280),
    double slideY = 0.15,
    int maxDelayMs = 120,
  }) {
    final delayMs = (index * stepMs).clamp(0, maxDelayMs);
    return EntranceFader(
      key: key ?? child.key,
      delay: Duration(milliseconds: delayMs),
      duration: duration,
      offset: Offset(0, slideY),
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

    if (widget.delay == Duration.zero) {
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
