import 'dart:async';

import 'package:flutter/material.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

class ArtistCard extends StatefulWidget {
  final Artist artist;
  final double? size;

  const ArtistCard({super.key, required this.artist, this.size});

  @override
  State<ArtistCard> createState() => _ArtistCardState();
}

class _ArtistCardState extends State<ArtistCard> {
  StreamSubscription<String>? _artworkSub;
  String? _effectiveArtwork;

  @override
  void initState() {
    super.initState();
    _resolveArtwork();
    _artworkSub = getIt<MetadataRepository>().onArtistArtworkUpdated.listen((
      updatedId,
    ) {
      if (updatedId == widget.artist.id && mounted) {
        _resolveArtwork();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ArtistCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artist.id != widget.artist.id) {
      _resolveArtwork();
    }
  }

  void _resolveArtwork() {
    final cached = getIt<MetadataRepository>().getCachedArtistArtworkPath(
      widget.artist.id,
    );
    final next = cached ?? widget.artist.artworkPath;
    if (next != _effectiveArtwork) {
      setState(() => _effectiveArtwork = next);
    }
  }

  @override
  void dispose() {
    _artworkSub?.cancel();
    super.dispose();
  }

  String _getInitials(String name) {
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
    final artwork = _effectiveArtwork;

    final cardContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: AspectRatio(
            aspectRatio: 1.0,
            child: artwork != null && artwork.isNotEmpty
                ? ArtworkImage(artwork)
                : Container(
                    color: colors.glassFill,
                    alignment: Alignment.center,
                    child: Text(
                      _getInitials(widget.artist.name),
                      style: TextStyle(
                        color: colors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: (widget.size ?? 95) * 0.32,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.artist.name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        if (widget.artist.trackCount > 0)
          Text(
            '${widget.artist.trackCount} ${widget.artist.trackCount > 1 ? 'titres' : 'titre'}',
            style: TextStyle(fontSize: 11, color: colors.labelSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
      ],
    );

    return GestureDetector(
      onTap: () => context.pushArtist(widget.artist.id),
      child: widget.size != null
          ? SizedBox(width: widget.size, child: cardContent)
          : cardContent,
    );
  }
}
