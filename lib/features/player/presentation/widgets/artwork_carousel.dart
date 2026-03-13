import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ArtworkCarousel extends StatefulWidget {
  final List<Track> queue;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const ArtworkCarousel({super.key, required this.queue, required this.currentIndex, required this.onPageChanged});

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
    return SizedBox(
      height: MediaQuery.of(context).size.width * 0.80,
      child: PageView.builder(
        controller: _pageCtrl,
        itemCount: widget.queue.length,
        onPageChanged: widget.onPageChanged,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageCtrl,
            builder: (_, child) {
              // Scale : page active = 1.0, adjacentes = 0.82
              double scale = 0.82;
              if (_pageCtrl.position.haveDimensions) {
                final delta = (_pageCtrl.page! - index).abs();
                scale = (1.0 - delta * 0.18).clamp(0.82, 1.0);
              } else if (index == widget.currentIndex) {
                scale = 1.0;
              }
              return Transform.scale(scale: scale, child: child);
            },
            child: _ArtworkItem(track: widget.queue[index], isActive: index == widget.currentIndex),
          );
        },
      ),
    );
  }
}

class _ArtworkItem extends StatelessWidget {
  final Track track;
  final bool isActive;
  const _ArtworkItem({required this.track, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Hero(
        // Tag partagé avec MiniPlayer — déclenche la transition
        tag: 'artwork_${track.id}',
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: isActive
                  ? [BoxShadow(color: Colors.black.withValues(alpha: .5), blurRadius: 30, offset: const Offset(0, 12))]
                  : [],
            ),
            child: track.artworkPath != null
                ? Image.file(
                    File(track.artworkPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _ArtworkPlaceholder(),
                  )
                : const _ArtworkPlaceholder(),
          ),
        ),
      ),
    );
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  const _ArtworkPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .08), borderRadius: BorderRadius.circular(16)),
      child: const Center(child: Icon(CupertinoIcons.music_note, size: 64, color: Colors.white30)),
    );
  }
}
