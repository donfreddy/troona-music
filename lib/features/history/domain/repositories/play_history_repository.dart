import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/history/domain/entities/play_event.dart';

abstract interface class PlayHistoryRepository {
  Future<Either<Failure, Unit>> record(PlayEvent event);

  /// Fires each time a play is recorded.
  Stream<void> get changes;

  /// Ids of the last played tracks, most recent first, each id once.
  Future<Either<Failure, List<String>>> recentTrackIds({required int limit});
}
