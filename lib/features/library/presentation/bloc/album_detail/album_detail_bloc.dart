import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:troona/features/library/domain/entities/album_detail.dart';
import 'package:troona/features/library/domain/repositories/album_detail_repository.dart';

part 'album_detail_event.dart';
part 'album_detail_state.dart';

class AlbumDetailBloc extends Bloc<AlbumDetailEvent, AlbumDetailState> {
  final AlbumDetailRepository _repo;

  AlbumDetailBloc({required AlbumDetailRepository repo})
    : _repo = repo,
      super(AlbumDetailInitial()) {
    // droppable: new events are ignored while a load is running
    on<AlbumDetailRequested>(_onAlbumDetailRequested, transformer: droppable());
  }

  Future<void> _onAlbumDetailRequested(
    AlbumDetailRequested event,
    Emitter<AlbumDetailState> emit,
  ) async {
    // Already loaded: keep the content instead of showing the full loading screen
    if (state is! AlbumDetailLoaded) {
      emit(const AlbumDetailLoading());
    }

    final result = await _repo.getAlbumById(event.id.toString());

    await result.fold(
      (failure) async => emit(AlbumDetailError(failure.message)),
      (album) async {
        // Once the album is loaded, fetch its tracks and the artist's other albums
        final tracksResult = await _repo.getTracksByAlbumId(event.id);

        await tracksResult.fold(
          (failure) async => emit(AlbumDetailError(failure.message)),
          (tracks) async {
            final artistAlbumsResult = await _repo.getAlbumsByArtistId(
              album.artistId,
            );

            await artistAlbumsResult.fold(
              (failure) async => emit(AlbumDetailError(failure.message)),
              (albums) async {
                emit(
                  AlbumDetailLoaded(
                    AlbumDetail(
                      album: album,
                      albumTracks: tracks,
                      artistAlbums: albums
                          .where((a) => a.name != album.name)
                          .toList(),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
