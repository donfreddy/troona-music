import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_by_ids_use_case.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/playlist/presentation/widgets/add_to_playlist_sheet.dart';
import 'package:troona/shared/widgets/action_sheet.dart';
import 'package:troona/shared/widgets/app_toast.dart';

enum TrackActionOrigin { library, album, artist, queue, nowPlaying }

void showTrackActions(
  BuildContext context,
  Track track, {
  TrackActionOrigin origin = TrackActionOrigin.library,
}) {
  final isLiked = context.read<LikesCubit>().state.isTrackLiked(track.id);
  final l10n = context.l10n;
  AppHaptics.mediumImpact();

  showActionSheet(
    context,
    title: track.title,
    message: context.artistName(track.artist),
    actions: [
      SheetAction(
        label: l10n.trackPlayNext,
        icon: AppIcons.playNext,
        onPressed: () {
          context.read<PlayerBloc>().add(TrackQueuedNext(track));
          AppToast.show(context, l10n.toastPlaysNext);
        },
      ),
      SheetAction(
        label: l10n.trackAddToQueue,
        icon: AppIcons.addToQueue,
        onPressed: () {
          context.read<PlayerBloc>().add(TrackAddedToQueue(track));
          AppToast.show(context, l10n.toastAddedToQueue);
        },
      ),
      SheetAction(
        label: isLiked ? l10n.likesRemove : l10n.trackLike,
        icon: isLiked ? AppIcons.unlike : AppIcons.like,
        onPressed: () {
          context.read<LikesCubit>().toggle(track);
          AppToast.show(context, isLiked ? l10n.toastUnliked : l10n.toastLiked);
        },
      ),
      SheetAction(
        label: l10n.trackAddToPlaylist,
        icon: AppIcons.addToPlaylist,
        onPressed: () => showAddToPlaylistSheet(context, track),
      ),
      if (origin != TrackActionOrigin.album)
        SheetAction(
          label: l10n.trackGoToAlbum,
          icon: AppIcons.album,
          onPressed: () => _goTo(
            context,
            track,
            origin,
            AppRoute.albumDetail,
            (t) => t.albumId,
          ),
        ),
      if (origin != TrackActionOrigin.artist)
        SheetAction(
          label: l10n.trackGoToArtist,
          icon: AppIcons.artist,
          onPressed: () => _goTo(
            context,
            track,
            origin,
            AppRoute.artistDetail,
            (t) => t.artistId,
          ),
        ),
    ],
  );
}

/// Opens the album or artist page of [track], with the ids the library holds
/// for it now: a song in the queue keeps the ids it had when it was queued,
/// and a scan may have moved it to another album or artist since.
Future<void> _goTo(
  BuildContext context,
  Track track,
  TrackActionOrigin origin,
  String route,
  int Function(Track) id,
) async {
  final router = GoRouter.of(context);
  if (origin == TrackActionOrigin.nowPlaying && context.canPop()) {
    context.pop();
  }
  final stored = (await getIt<GetTracksByIdsUseCase>()([
    track.id,
  ])).fold((_) => null, (tracks) => tracks.firstOrNull);
  router.goNamed(route, pathParameters: {'id': '${id(stored ?? track)}'});
}
