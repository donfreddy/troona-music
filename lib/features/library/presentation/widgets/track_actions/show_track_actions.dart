import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/playlist/presentation/widgets/add_to_playlist_sheet.dart';

enum TrackActionOrigin { library, album, artist, queue, nowPlaying }

void showTrackActions(
  BuildContext context,
  Track track, {
  TrackActionOrigin origin = TrackActionOrigin.library,
}) {
  final isLiked = context.read<LikesCubit>().state.isTrackLiked(track.id);

  showCupertinoModalPopup<void>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: Text(track.title),
      message: Text(track.artist),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(ctx);
            context.read<PlayerBloc>().add(TrackQueuedNext(track));
          },
          child: const Text('Play Next'),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(ctx);
            context.read<PlayerBloc>().add(TrackAddedToQueue(track));
          },
          child: const Text('Add to Queue'),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(ctx);
            context.read<LikesCubit>().toggle(track);
          },
          child: Text(isLiked ? 'Unlike' : 'Like'),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(ctx);
            showAddToPlaylistSheet(context, track);
          },
          child: const Text('Add to Playlist...'),
        ),
        if (origin != TrackActionOrigin.album)
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              context.goNamed(
                AppRoute.albumDetail,
                pathParameters: {'id': '${track.albumId}'},
              );
            },
            child: const Text('Go to Album'),
          ),
        if (origin != TrackActionOrigin.artist)
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              context.goNamed(
                AppRoute.artistDetail,
                pathParameters: {'id': '${track.artistId}'},
              );
            },
            child: const Text('Go to Artist'),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDestructiveAction: false,
        onPressed: () => Navigator.pop(ctx),
        child: const Text('Cancel'),
      ),
    ),
  );
}
