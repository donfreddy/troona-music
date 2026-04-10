import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/track.dart';

abstract interface class AlbumDetailRepository {
  Future<Either<Failure, Album>> getAlbumById(String id);

  Future<Either<Failure, List<Album>>> getAlbumsByArtistId(String id);

  // todo: remove and put to artiste details repo
  // Future<Either<Failure, List<Track>>> getTracksByArtistId(int id);

  Future<Either<Failure, List<Track>>> getTracksByAlbumId(int id);
}
