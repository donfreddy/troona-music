import 'package:flutter/material.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_by_ids_use_case.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

/// The cover of a playlist made of its songs' covers: four albums in a
/// 2 x 2 grid, else the first song's cover alone (two or three would repeat
/// in the grid), else a placeholder.
class PlaylistMosaic extends StatefulWidget {
  final List<String> trackIds;
  final double? size;

  const PlaylistMosaic({super.key, required this.trackIds, this.size});

  /// Songs read to find four albums.
  static const scanned = 32;

  /// The covers to show for [tracks] of a playlist whose songs are [ids],
  /// in that order: one per album, four or one, none without any.
  ///
  /// Covers are stored per song, so two songs of one album have two files
  /// of the same image: albums are told apart by id, not by path.
  @visibleForTesting
  static List<String> coversOf(List<String> ids, List<Track> tracks) {
    final byId = {for (final track in tracks) track.id: track};
    final albums = <int>{};
    final covers = <String>[];
    for (final id in ids) {
      final track = byId[id];
      final path = track?.artworkPath;
      if (track == null || path == null || path.isEmpty) continue;
      if (!albums.add(track.albumId)) continue;
      covers.add(path);
      if (covers.length == 4) return covers;
    }
    return covers.take(1).toList();
  }

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

    final first = ids.take(PlaylistMosaic.scanned).toList();
    final tracks = (await getIt<GetTracksByIdsUseCase>()(
      first,
    )).getOrElse(() => const []);
    final found = PlaylistMosaic.coversOf(first, tracks);

    // A later list may have been read first.
    if (mounted && identical(widget.trackIds, ids)) {
      setState(() {
        _artworks = found;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    if (!_loaded || _artworks.isEmpty) {
      return const ArtworkPlaceholder(icon: AppIcons.playlist);
    }
    if (_artworks.length < 4) {
      return ArtworkImage(_artworks.first, width: size, height: size);
    }

    final cell = size == null ? null : size / 2;
    Widget tile(int i) => Expanded(
      child: ArtworkImage(_artworks[i], width: cell, height: cell),
    );
    return ColoredBox(
      color: Colors.black,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [tile(0), const SizedBox(width: 1.5), tile(1)],
            ),
          ),
          const SizedBox(height: 1.5),
          Expanded(
            child: Row(
              children: [tile(2), const SizedBox(width: 1.5), tile(3)],
            ),
          ),
        ],
      ),
    );
  }
}
