import 'dart:async';

import 'package:flutter/material.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/presentation/widgets/artist_photo_hero.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

/// An artist as a circle, everywhere one is shown: their downloaded photo,
/// else their cover, else their initials. A photo downloaded or deleted
/// while it is on screen shows at once.
///
/// The photo flies to their page ([ArtistPhotoHero]) unless [hero] is
/// false: one circle per artist on a page may carry it.
class ArtistAvatar extends StatefulWidget {
  final Artist artist;
  final bool hero;

  const ArtistAvatar({super.key, required this.artist, this.hero = true});

  @override
  State<ArtistAvatar> createState() => _ArtistAvatarState();
}

class _ArtistAvatarState extends State<ArtistAvatar> {
  StreamSubscription<String>? _artworkSub;
  String? _artwork;

  /// Their downloaded photo, when it is the one shown: it flies to their
  /// page. A cover does not.
  String? _photo;

  @override
  void initState() {
    super.initState();
    _resolve();
    _artworkSub = getIt<MetadataRepository>().onArtistArtworkUpdated.listen((
      updatedId,
    ) {
      final mine =
          updatedId == widget.artist.id ||
          updatedId == MetadataRepository.allArtists;
      if (mine && mounted) _resolve();
    });
  }

  @override
  void didUpdateWidget(covariant ArtistAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artist.id != widget.artist.id ||
        oldWidget.artist.artworkPath != widget.artist.artworkPath) {
      _resolve();
    }
  }

  void _resolve() {
    final cached = getIt<MetadataRepository>().getCachedArtistArtworkPath(
      widget.artist.id,
    );
    final photo = cached != null && cached.isNotEmpty ? cached : null;
    final next = photo ?? widget.artist.artworkPath;
    if (next != _artwork || photo != _photo) {
      setState(() {
        _artwork = next;
        _photo = photo;
      });
    }
  }

  @override
  void dispose() {
    _artworkSub?.cancel();
    super.dispose();
  }

  static String _initials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final artwork = _artwork;
    final circle = ClipOval(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: artwork != null && artwork.isNotEmpty
            ? ArtworkImage(artwork, placeholder: AppIcons.artist)
            : Container(
                color: colors.subtleFill,
                alignment: Alignment.center,
                // Sized from the circle, not the phone's font size: a
                // drawing, which the name beside it already says.
                child: LayoutBuilder(
                  builder: (context, box) => Text(
                    _initials(widget.artist.name),
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      color: colors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: box.maxWidth * 0.32,
                    ),
                  ),
                ),
              ),
      ),
    );
    return switch (_photo) {
      final photo? when widget.hero => ArtistPhotoHero(
        artistId: widget.artist.id,
        photo: photo,
        round: true,
        child: circle,
      ),
      _ => circle,
    };
  }
}
