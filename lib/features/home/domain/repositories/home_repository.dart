import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/home/domain/entities/home_feed.dart';

abstract interface class HomeRepository {
  Future<Either<Failure, HomeFeed>> getFeed();

  /// Fires when the feed is out of date: a play was recorded, a scan
  /// changed the library, or a playlist changed. Writes come in bursts
  /// during a scan; callers coalesce them.
  Stream<void> get feedChanges;

  Future<Either<Failure, int>> getTotalTrackCount();
}
