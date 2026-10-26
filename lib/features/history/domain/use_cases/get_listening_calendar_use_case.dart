import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/history/domain/repositories/play_history_repository.dart';

/// The days of a month with at least one counted play, as days of the
/// month (1 to 31).
final class GetListeningCalendarUseCase {
  final PlayHistoryRepository _repo;
  const GetListeningCalendarUseCase(this._repo);

  Future<Either<Failure, Set<int>>> call(DateTime month) async {
    final first = ListeningDay.of(DateTime(month.year, month.month));
    final last = ListeningDay.of(DateTime(month.year, month.month + 1, 0));
    final days = await _repo.activeDays(firstDay: first, lastDay: last);
    return days.map((set) => {for (final d in set) d - first + 1});
  }
}
