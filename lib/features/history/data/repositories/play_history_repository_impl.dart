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
}
