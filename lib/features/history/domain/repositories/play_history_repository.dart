import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/history/domain/entities/listening_stats.dart';
import 'package:troona/features/history/domain/entities/play_event.dart';

abstract interface class PlayHistoryRepository {
  /// Records [event] and counts it in its day's totals.
  Future<Either<Failure, Unit>> record(PlayEvent event);

  /// Adds [listened] to the listening time of [day] (see `ListeningDay`).
  Future<Either<Failure, Unit>> recordListening(int day, Duration listened);

  /// Totals of the days from [firstDay] to [lastDay], both included.
  Future<Either<Failure, ListeningStats>> listeningStats({
    required int firstDay,
    required int lastDay,
  });

  /// The days from [firstDay] to [lastDay] with at least one counted play.
  Future<Either<Failure, Set<int>>> activeDays({
    required int firstDay,
    required int lastDay,
  });

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
