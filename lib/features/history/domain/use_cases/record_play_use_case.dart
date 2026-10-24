import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/history/domain/entities/play_event.dart';
import 'package:troona/features/history/domain/repositories/play_history_repository.dart';

final class RecordPlayUseCase {
  final PlayHistoryRepository _repo;
  const RecordPlayUseCase(this._repo);

  Future<Either<Failure, Unit>> call(PlayEvent event) => _repo.record(event);
}
