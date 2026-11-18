import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/library/domain/entities/artist_credit.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/services/track_tags.dart';
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
  // Opening a menu: a small step.
  AppHaptics.lightImpact();

  showActionSheet(
    context,
    title: track.title,
    message: context.artistName(track.artist),
    actions: [
      SheetAction(
        label: l10n.trackPlayNext,
        icon: AppIcons.playNext,
        onPressed: () {
          final player = context.read<PlayerBloc>();
          final queues = player.hasQueue;
          player.add(TrackQueuedNext(track));
          // With nothing loaded it plays: the mini player says so.
          if (queues) AppToast.show(context, l10n.toastPlaysNext);
        },
      ),
      SheetAction(
        label: l10n.trackAddToQueue,
        icon: AppIcons.addToQueue,
        onPressed: () {
          final player = context.read<PlayerBloc>();
          final queues = player.hasQueue;
          player.add(TrackAddedToQueue(track));
          if (queues) AppToast.show(context, l10n.toastAddedToQueue);
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
          onPressed: () =>
              _goTo(context, track, origin, 'albums', (t) => t.albumId),
        ),
      if (origin != TrackActionOrigin.artist)
        SheetAction(
          label: l10n.trackGoToArtist,
          icon: AppIcons.artist,
          onPressed: () => openArtistOf(context, track, origin: origin),
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
  String section,
  int Function(Track) id,
) async {
  final router = GoRouter.of(context);
  if (origin == TrackActionOrigin.nowPlaying && context.canPop()) {
    context.pop();
  }
  final stored = await _stored(track);
  pushDetailInTab(router, section, '${id(stored ?? track)}');
}

/// [track] as the library holds it now, or null when it is gone.
Future<Track?> _stored(Track track) async =>
    (await getIt<GetTracksByIdsUseCase>()([
      track.id,
    ])).fold((_) => null, (tracks) => tracks.firstOrNull);

/// Opens the page of [track]'s artist, read again from the library first
/// (see [_goTo]). A song crediting several artists asks which one; a song
/// without an artist opens nothing.
bool _readingArtist = false;

Future<void> openArtistOf(
  BuildContext context,
  Track track, {
  TrackActionOrigin origin = TrackActionOrigin.library,
}) async {
  // A second tap while the first reads the library would open the page
  // twice, or stack a second sheet. Once a sheet is up, its barrier takes
  // the taps.
  if (_readingArtist) return;
  final router = GoRouter.of(context);
  _readingArtist = true;
  final Track? stored;
  try {
    stored = await _stored(track);
  } finally {
    _readingArtist = false;
  }
  final credits = [
    for (final c in (stored ?? track).credits)
      if (!TrackTags.isUnknownArtist(c.name)) c,
  ];
  if (credits.isEmpty || !context.mounted) return;

  void open(ArtistCredit credit) {
    if (origin == TrackActionOrigin.nowPlaying && context.canPop()) {
      context.pop();
    }
    pushDetailInTab(router, 'artists', '${credit.id}');
  }

  if (credits.length == 1) return open(credits.single);
  await showActionSheet(
    context,
    title: context.l10n.trackGoToArtist,
    actions: [
      for (final credit in credits)
        SheetAction(
          label: credit.name,
          icon: AppIcons.artist,
          onPressed: () => open(credit),
        ),
    ],
  );
}
