import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/playlist/domain/repositories/playlist_repository.dart';

part 'playlist_event.dart';
part 'playlist_state.dart';

class PlaylistBloc extends Bloc<PlaylistEvent, PlaylistState> {
  final PlaylistRepository _repo;

  PlaylistBloc({required PlaylistRepository repo})
    : _repo = repo,
      super(PlaylistInitial()) {
    on<PlaylistListRequested>(_onListRequested, transformer: droppable());
    on<PlaylistCreateRequested>(_onCreateRequested, transformer: droppable());
    on<PlaylistRenameRequested>(_onRenameRequested, transformer: droppable());
    on<PlaylistDeleteRequested>(_onDeleteRequested, transformer: droppable());
  }

  Future<void> _onListRequested(
    PlaylistListRequested event,
    Emitter<PlaylistState> emit,
  ) async {
    if (state is! PlaylistLoaded) emit(PlaylistLoading());

    final result = await _repo.getPlaylists();
    result.fold(
      (f) => emit(PlaylistError(f.message)),
      (playlists) => emit(PlaylistLoaded(playlists)),
    );
  }

  Future<void> _onCreateRequested(
    PlaylistCreateRequested event,
    Emitter<PlaylistState> emit,
  ) async {
    final result = await _repo.createPlaylist(
      title: event.title,
      description: event.description,
    );

    await result.fold((f) async => emit(PlaylistError(f.message)), (_) async {
      final listResult = await _repo.getPlaylists();
      listResult.fold(
        (f) => emit(PlaylistError(f.message)),
        (playlists) => emit(PlaylistLoaded(playlists)),
      );
    });
  }

  /// Renames from the stored playlist, not the listed one: the list may be
  /// older than songs added since, and an update writes the songs too.
  Future<void> _onRenameRequested(
    PlaylistRenameRequested event,
    Emitter<PlaylistState> emit,
  ) async {
    final stored = await _repo.getPlaylistById(event.id);
    final result = await stored.fold(
      (f) async => left<Failure, Unit>(f),
      (playlist) => _repo.updatePlaylist(
        Playlist(
          id: playlist.id,
          name: event.name,
          trackIds: playlist.trackIds,
          artworkPath: playlist.artworkPath,
        ),
      ),
    );

    await result.fold((f) async => emit(PlaylistError(f.message)), (_) async {
      final listResult = await _repo.getPlaylists();
      listResult.fold(
        (f) => emit(PlaylistError(f.message)),
        (playlists) => emit(PlaylistLoaded(playlists)),
      );
    });
  }

  Future<void> _onDeleteRequested(
    PlaylistDeleteRequested event,
    Emitter<PlaylistState> emit,
  ) async {
    final result = await _repo.deletePlaylist(event.id);

    await result.fold((f) async => emit(PlaylistError(f.message)), (_) async {
      final listResult = await _repo.getPlaylists();
      listResult.fold(
        (f) => emit(PlaylistError(f.message)),
        (playlists) => emit(PlaylistLoaded(playlists)),
      );
    });
  }
}
