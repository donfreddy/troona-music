import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:troona/features/playlist/domain/entities/playlist_detail.dart';
import 'package:troona/features/playlist/domain/repositories/playlist_repository.dart';

part 'playlist_detail_event.dart';
part 'playlist_detail_state.dart';

class PlaylistDetailBloc extends Bloc<PlaylistDetailEvent, PlaylistDetailState> {
  final PlaylistRepository _repo;

  PlaylistDetailBloc({required PlaylistRepository repo})
      : _repo = repo,
        super(PlaylistDetailInitial()) {
    on<PlaylistDetailRequested>(_onDetailRequested, transformer: droppable());
    on<PlaylistAddTrackRequested>(_onAddTrackRequested, transformer: droppable());
    on<PlaylistRemoveTrackRequested>(_onRemoveTrackRequested, transformer: droppable());
    on<PlaylistReorderTracksRequested>(_onReorderTracksRequested, transformer: droppable());
  }

  Future<void> _onDetailRequested(
    PlaylistDetailRequested event,
    Emitter<PlaylistDetailState> emit,
  ) async {
    if (state is! PlaylistDetailLoaded) emit(PlaylistDetailLoading());

    final playlistResult = await _repo.getPlaylistById(event.id);
    final tracksResult = await _repo.getTracksByPlaylistId(event.id);

    playlistResult.fold(
      (f) => emit(PlaylistDetailError(f.message)),
      (playlist) {
        final tracks = tracksResult.getOrElse(() => []);
        emit(PlaylistDetailLoaded(
          PlaylistDetail(playlist: playlist, tracks: tracks),
        ));
      },
    );
  }

  Future<void> _onAddTrackRequested(
    PlaylistAddTrackRequested event,
    Emitter<PlaylistDetailState> emit,
  ) async {
    final result = await _repo.addTrackToPlaylist(event.playlistId, event.trackId);
    result.fold(
      (f) => emit(PlaylistDetailError(f.message)),
      (_) => add(PlaylistDetailRequested(event.playlistId)),
    );
  }

  Future<void> _onRemoveTrackRequested(
    PlaylistRemoveTrackRequested event,
    Emitter<PlaylistDetailState> emit,
  ) async {
    final result = await _repo.removeTrackFromPlaylist(event.playlistId, event.trackId);
    result.fold(
      (f) => emit(PlaylistDetailError(f.message)),
      (_) => add(PlaylistDetailRequested(event.playlistId)),
    );
  }

  Future<void> _onReorderTracksRequested(
    PlaylistReorderTracksRequested event,
    Emitter<PlaylistDetailState> emit,
  ) async {
    final result = await _repo.reorderTracks(event.playlistId, event.oldIndex, event.newIndex);
    result.fold(
      (f) => emit(PlaylistDetailError(f.message)),
      (_) => add(PlaylistDetailRequested(event.playlistId)),
    );
  }
}
