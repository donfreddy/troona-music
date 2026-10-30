import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_by_ids_use_case.dart';
import 'package:troona/features/player/data/adapters/resumable_session.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';

/// The saved session, offered back by the system media controls.
///
/// Resuming goes through [PlayerBloc], the way the app restores a session on
/// launch, so the app shows it when opened. That matters when the system
/// starts the app without its UI: nothing else would restore the session.
final class PlaybackResumer implements ResumableSession {
  final PlaybackSessionStore _store;
  final GetTracksByIdsUseCase _getTracksByIds;
  final PlayerBloc _player;

  PlaybackResumer({
    required PlaybackSessionStore store,
    required GetTracksByIdsUseCase getTracksByIds,
    required PlayerBloc player,
  }) : _store = store,
       _getTracksByIds = getTracksByIds,
       _player = player;

  @override
  Future<Track?> lastTrack() async {
    final snapshot = _store.load();
    if (snapshot == null) return null;
    final tracks = await _getTracksByIds([snapshot.currentTrackId]);
    return tracks.fold((_) => null, (found) => found.firstOrNull);
  }

  @override
  Future<void> resume() async =>
      _player.add(const RestorePlaybackSessionRequested(play: true));
}
