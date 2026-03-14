import 'package:flutter/material.dart';
import 'package:troona/features/library/domain/entities/track.dart';

class TrackListTile extends StatefulWidget {
  final Track track;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const TrackListTile({
    super.key,
    required this.track,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<TrackListTile> createState() => _TrackListTileState();
}

class _TrackListTileState extends State<TrackListTile> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
