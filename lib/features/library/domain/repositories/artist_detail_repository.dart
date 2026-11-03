import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/artist_albums.dart';
import 'package:troona/features/library/domain/entities/track.dart';

abstract interface class ArtistDetailRepository {
  Future<Either<Failure, Artist>> getArtistById(String id);
  Future<Either<Failure, List<Track>>> getTopTracksByArtistId(String id);

  /// The artist's own albums and the ones they appear on.
  Future<Either<Failure, ArtistAlbums>> getAlbumsByArtistId(String id);
}
