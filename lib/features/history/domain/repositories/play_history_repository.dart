import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/history/domain/entities/play_event.dart';

abstract interface class PlayHistoryRepository {
  Future<Either<Failure, Unit>> record(PlayEvent event);

  /// Fires each time a play is recorded.
  Stream<void> get changes;

  /// Ids of the last played tracks, most recent first, each id once.
  Future<Either<Failure, List<String>>> recentTrackIds({required int limit});

  /// Map of {trackId: playCount} for the last [days], sorted by count desc.
  Future<Either<Failure, Map<String, int>>> topTrackIds({
    int days = 7,
    int limit = 5,
  });

  /// Liked track IDs that have not been played in [staleDays] days.
  Future<Either<Failure, List<String>>> forgottenTrackIds(
    Set<String> likedIds, {
    int staleDays = 14,
    int limit = 5,
  });

  /// Total plays in the last [days] days.
  Future<Either<Failure, int>> totalPlays({int days = 7});
}

