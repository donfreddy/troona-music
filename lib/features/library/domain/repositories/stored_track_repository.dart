import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/track.dart';

/// Every song stored on this phone, the ones the user's scan filter leaves
/// out of the library included (`ScanFilter`). The library itself never
/// shows those; a restore still finds them, and the folders page counts
/// them.
abstract interface class StoredTrackRepository {
  Future<Either<Failure, List<Track>>> getStoredTracks();
}
