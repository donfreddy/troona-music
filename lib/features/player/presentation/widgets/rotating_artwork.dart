import 'dart:io';

import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:troona/features/library/domain/entities/track.dart';

class RotatingArtwork extends StatefulWidget {
  final Track? track;
  final bool isPlaying;
  final double size;

  const RotatingArtwork({
    super.key,
    required this.track,
    required this.isPlaying,
    this.size = 52,
  });

  @override
  State<RotatingArtwork> createState() => _RotatingArtworkState();
}

class _RotatingArtworkState extends State<RotatingArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12), // 1 tour complet en 12s
    );
    if (widget.isPlaying) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(RotatingArtwork old) {
    super.didUpdateWidget(old);

    if (widget.isPlaying && !old.isPlaying) {
      // Reprend depuis l'angle courant — pas de saut
      _ctrl.repeat();
    } else if (!widget.isPlaying && old.isPlaying) {
      // Ralentit et s'arrête proprement
      _ctrl.stop();
    }

    // Nouveau track → repart à 0 (optionnel — tu peux garder l'angle)
    if (widget.track?.id != old.track?.id) {
      _ctrl.reset();
      if (widget.isPlaying) _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: Hero(
        tag: 'artwork_${widget.track?.id ?? 'none'}',
        child: SizedBox.square(
          dimension: widget.size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .45),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: widget.track?.artworkPath != null
                  ? Image.file(
                      File(widget.track!.artworkPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder,
                    )
                  : _placeholder,
            ),
          ),
        ),
      ),
    );
  }

  Widget get _placeholder => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .12),
      shape: BoxShape.circle,
    ),
    child: const Icon(
      EvaIcons.music,
      color: Colors.white38,
      //size: 22,
    ),
  );
}
