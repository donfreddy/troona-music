import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/track.dart';

/// Every song stored on this phone: the library's, and the ones the user's
/// scan filter leaves out (`ScanFilter`), which the library never shows.
/// Each as its file describes it, under any correction made in the app:
/// backups describe songs so, and a restore matches them so.
final class StoredTracks {
  /// The songs of the library.
  final List<Track> kept;

  /// The songs a folder turned off or the shortest length leaves out.
  final List<Track> leftOut;

  const StoredTracks({required this.kept, required this.leftOut});

  List<Track> get all => [...kept, ...leftOut];
}

/// The songs a restore looks in (the library's first, so a left-out copy
/// never takes a song the library holds) and the folders page counts.
abstract interface class StoredTrackRepository {
  Future<Either<Failure, StoredTracks>> getStoredTracks();
}
