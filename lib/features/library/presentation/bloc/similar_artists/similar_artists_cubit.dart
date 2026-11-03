import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/repositories/artist_detail_repository.dart';

/// The artists of the library that Last.fm finds similar to the one whose
/// page is open: "Also in your library". Empty until loaded, and when none
/// of them is in the library.
class SimilarArtistsCubit extends Cubit<List<Artist>> {
  final ArtistDetailRepository _repo;
  int _generation = 0;

  SimilarArtistsCubit({required ArtistDetailRepository repo})
    : _repo = repo,
      super(const []);

  /// Looks [names] up in the library, leaving out the artist [exceptId]
  /// whose page it is. A later call wins over one still running.
  Future<void> load(List<String> names, {required String exceptId}) async {
    final generation = ++_generation;
    final found = (await _repo.getArtistsByNames(
      names,
    )).getOrElse(() => const []);
    if (isClosed || generation != _generation) return;
    emit([
      for (final artist in found)
        if (artist.id != exceptId) artist,
    ]);
  }
}
