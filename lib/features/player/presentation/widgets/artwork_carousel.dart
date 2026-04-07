import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/features/library/domain/entities/track.dart';

class ArtworkCarousel extends StatefulWidget {
  final List<Track> queue;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const ArtworkCarousel({
    super.key,
    required this.queue,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  State<ArtworkCarousel> createState() => _ArtworkCarouselState();
}

class _ArtworkCarouselState extends State<ArtworkCarousel> {
  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(
      initialPage: widget.currentIndex,
      viewportFraction: 0.72, // les pochettes adjacentes sont visibles
    );
  }

  @override
  void didUpdateWidget(ArtworkCarousel old) {
    super.didUpdateWidget(old);
    // Quand le Bloc skip une piste, on anime la page
    if (old.currentIndex != widget.currentIndex) {
      _pageCtrl.animateToPage(
        widget.currentIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : context.screenWidth;

        return SizedBox(
          width: width,
          height: width * 0.85,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.queue.length,
            onPageChanged: widget.onPageChanged,
            itemBuilder: (_, index) {
              return AnimatedBuilder(
                animation: _pageCtrl,
                builder: (_, child) {
                  // Scale : page active = 1.0, adjacentes = 0.82
                  double scale = 0.82;
                  if (_pageCtrl.hasClients &&
                      _pageCtrl.position.haveDimensions) {
                    final delta = (_pageCtrl.page! - index).abs();
                    scale = (1.0 - delta * 0.18).clamp(0.82, 1.0);
                  } else if (index == widget.currentIndex) {
                    scale = 1.0;
                  }
                  return Transform.scale(scale: scale, child: child);
                },
                child: _ArtworkItem(
                  track: widget.queue[index],
                  isActive: index == widget.currentIndex,
                  ringSize: width * 0.62,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ArtworkItem extends StatelessWidget {
  final Track track;
  final bool isActive;
  final double ringSize;

  const _ArtworkItem({
    required this.track,
    required this.isActive,
    required this.ringSize,
  });

  @override
  Widget build(BuildContext context) {
    //final size = MediaQuery.of(context).size.width * 0.62;
    final artSize = ringSize * 0.68;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // ── Anneaux vinyle — uniquement sur l'artwork actif ──
        if (isActive) ...[
          // Anneau extérieur — plus transparent
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .08),
                    width: 22,
                  ),
                  color: Colors.black.withValues(alpha: .25),
                ),
              ),
            ),
          ),
          // Anneau intermédiaire
          Container(
            width: ringSize * 0.86,
            height: ringSize * 0.86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: .05),
                width: 10,
              ),
            ),
          ),

          // // Cercle glassmorphism derrière l'artwork
          // ClipOval(
          //   child: BackdropFilter(
          //     filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          //     child: Container(width: size * 0.75, height: size * 0.75, color: Colors.white.withValues(alpha: .04)),
          //   ),
          // ),
        ],

        // ── Artwork rond ──────────────────────────────────
        Hero(
          tag: 'artwork_${track.id}',
          child: ClipOval(
            child: SizedBox.square(
              dimension: isActive ? artSize : artSize * 0.72,
              child: track.artworkPath != null
                  ? Image.file(File(track.artworkPath!), fit: BoxFit.cover)
                  : const _ArtworkPlaceholder(),
            ),
          ),
        ),

        // ── Durée totale sous l'artwork ───────────────────
        if (isActive)
          Positioned(
            bottom: ringSize * 0.06,
            child: Text(
              Duration(milliseconds: track.durationMs).toMMSS(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: .55),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  const _ArtworkPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(CupertinoIcons.music_note, size: 64, color: Colors.white30),
      ),
    );
  }
}
