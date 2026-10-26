import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/utils/haptics_helper.dart';
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
  AppHaptics.mediumImpact();

  showCupertinoModalPopup<void>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: Text(track.title),
      message: Text(track.artist),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(ctx);
            AppHaptics.selectionClick();
            context.read<PlayerBloc>().add(TrackQueuedNext(track));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Playing next: ${track.title}'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: const Text('Play Next'),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(ctx);
            AppHaptics.selectionClick();
            context.read<PlayerBloc>().add(TrackAddedToQueue(track));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added to queue: ${track.title}'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: const Text('Add to Queue'),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(ctx);
            AppHaptics.selectionClick();
            context.read<LikesCubit>().toggle(track);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isLiked ? 'Removed from Likes' : 'Added to Likes',
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Text(isLiked ? 'Unlike' : 'Like'),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(ctx);
            AppHaptics.selectionClick();
            showAddToPlaylistSheet(context, track);
          },
          child: const Text('Add to Playlist...'),
        ),
        if (origin != TrackActionOrigin.album)
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              AppHaptics.selectionClick();
              if (origin == TrackActionOrigin.nowPlaying && context.canPop()) {
                context.pop();
              }
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
              AppHaptics.selectionClick();
              if (origin == TrackActionOrigin.nowPlaying && context.canPop()) {
                context.pop();
              }
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
