import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/album_detail_repository.dart';
import 'package:troona/features/player/domain/entities/queue_origin.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/utils/play_shuffled.dart';
import 'package:troona/shared/widgets/action_sheet.dart';
import 'package:troona/shared/widgets/app_toast.dart';

/// The album's menu: a long press on its card, or its page's options.
/// Play and Shuffle are left out where the page shows them as buttons
/// ([withPlay] false).
///
/// [tracks] are the album's songs in its order, when known (its page);
/// otherwise they are read when an action is chosen, so the sheet opens at
/// once.
void showAlbumActions(
  BuildContext context,
  Album album, {
  List<Track>? tracks,
  bool withPlay = true,
}) {
  final l10n = context.l10n;
  final player = context.read<PlayerBloc>();
  AppHaptics.mediumImpact();

  final origin = QueueOrigin(
    QueueOriginKind.album,
    id: album.id,
    name: album.name,
  );

  /// Runs [action] on the album's songs, read first if need be.
  Future<void> withTracks(void Function(List<Track> tracks) action) async {
    final songs = tracks ?? await albumTracks(album);
    if (songs.isNotEmpty) action(songs);
  }

  void toast(String message) {
    if (context.mounted) AppToast.show(context, message);
  }

  showActionSheet(
    context,
    title: album.name,
    message: l10n.albumByArtist(
      context.artistName(album.artist),
      l10n.songCount(tracks?.length ?? album.trackCount),
    ),
    actions: [
      if (withPlay) ...[
        SheetAction(
          label: l10n.actionPlay,
          icon: AppIcons.play,
          onPressed: () => withTracks(
            (songs) => player.add(
              PlayTrackRequested(
                songs.first,
                contextQueue: songs,
                contextIndex: 0,
                origin: origin,
              ),
            ),
          ),
        ),
        SheetAction(
          label: l10n.actionShuffle,
          icon: AppIcons.shuffle,
          onPressed: () => withTracks(
            (songs) => playShuffled(player, songs, origin: origin),
          ),
        ),
      ],
      SheetAction(
        label: l10n.trackPlayNext,
        icon: AppIcons.playNext,
        onPressed: () => withTracks((songs) {
          // Each goes right after the current song: the last one first.
          for (final track in songs.reversed) {
            player.add(TrackQueuedNext(track));
          }
          toast(l10n.toastPlaysNext);
        }),
      ),
      SheetAction(
        label: l10n.trackAddToQueue,
        icon: AppIcons.addToQueue,
        onPressed: () => withTracks((songs) {
          for (final track in songs) {
            player.add(TrackAddedToQueue(track));
          }
          toast(l10n.toastAddedToQueue);
        }),
      ),
    ],
  );
}

/// The songs of [album] in its order, none when they cannot be read.
@visibleForTesting
Future<List<Track>> albumTracks(Album album) async {
  final id = int.tryParse(album.id);
  if (id == null) return const [];
  return (await getIt<AlbumDetailRepository>().getTracksByAlbumId(
    id,
  )).fold((_) => const [], (tracks) => tracks);
}
