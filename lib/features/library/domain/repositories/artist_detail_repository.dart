import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/artist_albums.dart';
import 'package:troona/features/library/domain/entities/artist_songs.dart';

abstract interface class ArtistDetailRepository {
  Future<Either<Failure, Artist>> getArtistById(String id);

  /// Every song that credits the artist, most played first.
  Future<Either<Failure, ArtistSongs>> getTopTracksByArtistId(String id);

  /// The artist's own albums and the ones they appear on.
  Future<Either<Failure, ArtistAlbums>> getAlbumsByArtistId(String id);

  /// The artists of the library among [names], in that order, matched by
  /// name as `TrackTags.artistIdFor` keys them. Names of artists the
  /// library does not hold are left out.
  Future<Either<Failure, List<Artist>>> getArtistsByNames(List<String> names);
}
