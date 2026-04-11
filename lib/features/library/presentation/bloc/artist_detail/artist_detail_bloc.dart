import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/artist_detail.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/artist_detail_repository.dart';

part 'artist_detail_event.dart';
part 'artist_detail_state.dart';

class ArtistDetailBloc extends Bloc<ArtistDetailEvent, ArtistDetailState> {
  final ArtistDetailRepository _repo;

  ArtistDetailBloc({required ArtistDetailRepository repo})
    : _repo = repo,
      super(ArtistDetailInitial()) {
    on<ArtistDetailRequested>(
      _onArtistDetailRequested,
      transformer: droppable(),
    );
  }

  Future<void> _onArtistDetailRequested(
    ArtistDetailRequested event,
    Emitter<ArtistDetailState> emit,
  ) async {
    if (state is! ArtistDetailLoaded) {
      emit(const ArtistDetailLoading());
    }

    final id = event.id.toString();

    // On lance les 3 requêtes en parallèle pour la performance
    final results = await Future.wait([
      _repo.getArtistById(id),
      _repo.getTopTracksByArtistId(id),
      _repo.getAlbumsByArtistId(id),
    ]);

    final artistRes = results[0] as Either<Failure, Artist>;
    final tracksRes = results[1] as Either<Failure, List<Track>>;
    final albumsRes = results[2] as Either<Failure, List<Album>>;

    artistRes.fold((f) => emit(ArtistDetailError(f.message)), (artist) {
      final tracks = tracksRes.getOrElse(() => []);
      final albums = albumsRes.getOrElse(() => []);

      emit(
        ArtistDetailLoaded(
          ArtistDetail(artist: artist, topTracks: tracks, albums: albums),
        ),
      );
    });
  }
}
