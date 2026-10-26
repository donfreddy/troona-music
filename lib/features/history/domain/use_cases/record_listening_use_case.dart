import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/history/domain/repositories/play_history_repository.dart';

final class RecordListeningUseCase {
  final PlayHistoryRepository _repo;
  const RecordListeningUseCase(this._repo);

  Future<Either<Failure, Unit>> call(int day, Duration listened) =>
      _repo.recordListening(day, listened);
}
