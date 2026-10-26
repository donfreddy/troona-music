import 'package:dartz/dartz.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/history/data/models/play_event_model.dart';
import 'package:troona/features/history/data/sources/isar_play_history_data_source.dart';
import 'package:troona/features/history/domain/entities/play_event.dart';
import 'package:troona/features/history/domain/repositories/play_history_repository.dart';

final class PlayHistoryRepositoryImpl implements PlayHistoryRepository {
  final IsarPlayHistoryDataSource _source;

  const PlayHistoryRepositoryImpl(this._source);

  @override
  Stream<void> get changes => _source.watch();

  @override
  Future<Either<Failure, Unit>> record(PlayEvent event) async {
    try {
      await _source.add(PlayEventModel.fromEntity(event));
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, List<String>>> recentTrackIds({
    required int limit,
  }) async {
    try {
      return right(await _source.recentTrackIds(limit: limit));
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> topTrackIds({
    int days = 7,
    int limit = 5,
  }) async {
    try {
      return right(_source.topTrackIds(days: days, limit: limit));
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, List<String>>> forgottenTrackIds(
    Set<String> likedIds, {
    int staleDays = 14,
    int limit = 5,
  }) async {
    try {
      return right(
        _source.forgottenTrackIds(likedIds, staleDays: staleDays, limit: limit),
      );
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, int>> totalPlays({int days = 7}) async {
    try {
      return right(_source.totalPlays(days: days));
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }
}
