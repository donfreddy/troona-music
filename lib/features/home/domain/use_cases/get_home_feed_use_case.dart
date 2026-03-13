import 'package:dartz/dartz.dart';
import 'package:troona/features/home/domain/entities/home_feed.dart';
import 'package:troona/features/home/domain/repositories/home_repository.dart';

final class GetHomeFeedUseCase {
  final HomeRepository _repo;
  const GetHomeFeedUseCase(this._repo);

  Future<Either<Failure, HomeFeed>> call(NoParams _) => _repo.getFeed();
}
