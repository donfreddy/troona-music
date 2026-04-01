import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/home/domain/entities/home_feed.dart';

abstract interface class HomeRepository {
  Future<Either<Failure, HomeFeed>> getFeed();
  Future<Either<Failure, int>> getTotalTrackCount();
}
