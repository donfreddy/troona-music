import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/track.dart';

abstract interface class ArtistDetailRepository {
  Future<Either<Failure, Artist>> getArtistById(String id);
  Future<Either<Failure, List<Track>>> getTopTracksByArtistId(String id);
  Future<Either<Failure, List<Album>>> getAlbumsByArtistId(String id);
}
