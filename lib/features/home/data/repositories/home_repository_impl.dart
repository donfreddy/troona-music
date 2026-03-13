import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/home/domain/entities/home_feed.dart';
import 'package:troona/features/home/domain/repositories/home_repository.dart';
import 'package:troona/features/library/data/models/track_model.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';

final class HomeRepositoryImpl implements HomeRepository {
  final IsarLibraryDataSource _db;

  const HomeRepositoryImpl({required IsarLibraryDataSource db}) : _db = db;

  @override
  Future<Either<Failure, HomeFeed>> getFeed() async {
    try {
      final results = await Future.wait([_db.getPlaylists(limit: 6), _db.getRecentTracks(limit: 20)]);

      return right(
        HomeFeed(
          popularPlaylists: (results[0] as List<PlaylistModel>).map((p) => p.toEntity()).toList(),
          trendingTracks: (results[1] as List<TrackModel>).map((t) => t.toEntity()).toList(),
        ),
      );
    } catch (e) {
      return left(DatabaseFailure(e.toString()));
    }
  }
}
