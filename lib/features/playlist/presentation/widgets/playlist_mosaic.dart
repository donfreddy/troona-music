import 'package:flutter/material.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_by_ids_use_case.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

/// Intelligent mosaic cover for playlists.
///
/// Automatically adapts based on available covers:
/// - 0 covers: Elegant subtle dark gradient with a music icon.
/// - 1 cover: Full 100% artwork view.
/// - 2+ covers: Balanced 2x2 mosaic grid with fine dividers.
class PlaylistMosaic extends StatefulWidget {
  final List<String> trackIds;
  final double? size;

  const PlaylistMosaic({super.key, required this.trackIds, this.size});

  @override
  State<PlaylistMosaic> createState() => _PlaylistMosaicState();
}

class _PlaylistMosaicState extends State<PlaylistMosaic> {
  List<String> _artworks = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _resolveArtworks();
  }

  @override
  void didUpdateWidget(covariant PlaylistMosaic oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trackIds != widget.trackIds) {
      _resolveArtworks();
    }
  }

  Future<void> _resolveArtworks() async {
    final ids = widget.trackIds;
    if (ids.isEmpty) {
      if (mounted) setState(() => _loaded = true);
      return;
    }

    final tracks = (await getIt<GetTracksByIdsUseCase>()(
      ids.take(16).toList(),
    )).getOrElse(() => const []);
    final found = <String>[];
    final seen = <String>{};

    for (final track in tracks) {
      final path = track.artworkPath;
      if (path != null && path.isNotEmpty && seen.add(path)) {
        found.add(path);
        if (found.length >= 4) break;
      }
    }

    if (mounted) {
      setState(() {
        _artworks = found;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Loading / Empty state
    if (!_loaded || _artworks.isEmpty) {
      return Container(
        color: colors.glassFill,
        child: Center(
          child: Icon(
            AppIcons.playlist,
            color: colors.labelTertiary,
            size: (widget.size ?? 60) * 0.42,
          ),
        ),
      );
    }

    // 1 single cover: Show full size!
    if (_artworks.length == 1) {
      return ArtworkImage(_artworks[0]);
    }

    // 2 or 3 or 4 covers: Show 2x2 grid with fine micro-divider
    return ColoredBox(
      color: Colors.black,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: ArtworkImage(_artworks[0])),
                const SizedBox(width: 1.5),
                Expanded(
                  child: _artworks.length > 1
                      ? ArtworkImage(_artworks[1])
                      : Container(color: colors.glassFill),
                ),
              ],
            ),
          ),
          const SizedBox(height: 1.5),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _artworks.length > 2
                      ? ArtworkImage(_artworks[2])
                      : ArtworkImage(_artworks[0]),
                ),
                const SizedBox(width: 1.5),
                Expanded(
                  child: _artworks.length > 3
                      ? ArtworkImage(_artworks[3])
                      : (_artworks.length > 1
                            ? ArtworkImage(_artworks[1])
                            : Container(color: colors.glassFill)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
