import 'package:flutter/material.dart';
import 'package:troona/features/library/domain/entities/artist.dart';

class ArtistCard extends StatefulWidget {
  final Artist artist;

  const ArtistCard({super.key, required this.artist});

  @override
  State<ArtistCard> createState() => _ArtistCardState();
}

class _ArtistCardState extends State<ArtistCard> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
