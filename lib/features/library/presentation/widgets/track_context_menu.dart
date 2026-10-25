import 'package:flutter/material.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/widgets/track_actions/show_track_actions.dart';

class TrackContextMenu extends StatelessWidget {
  final Track track;
  final TrackActionOrigin origin;

  const TrackContextMenu({
    super.key,
    required this.track,
    this.origin = TrackActionOrigin.library,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showTrackActions(context, track, origin: origin),
      child: const Padding(
        padding: EdgeInsets.all(8),
        child: Icon(Icons.more_vert, size: 20),
      ),
    );
  }
}
