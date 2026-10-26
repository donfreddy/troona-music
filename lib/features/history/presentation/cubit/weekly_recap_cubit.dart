import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/history/domain/entities/weekly_recap.dart';
import 'package:troona/features/history/domain/use_cases/get_listening_calendar_use_case.dart';
import 'package:troona/features/history/domain/use_cases/get_weekly_recap_use_case.dart';

final class WeeklyRecapState extends Equatable {
  final bool loading;

  /// Null when last week had no plays: the Home card is then hidden.
  final WeeklyRecap? recap;

  /// The month the calendar shows: the current one.
  final DateTime month;

  /// Days of [month] (1 to 31) with at least one counted play.
  final Set<int> activeDays;

  const WeeklyRecapState({
    required this.month,
    this.loading = true,
    this.recap,
    this.activeDays = const {},
  });

  @override
  List<Object?> get props => [loading, recap, month, activeDays];
}

/// "Your week in music" for the Home card and its page. A read failure
/// shows as no recap: the card is a bonus, not worth an error.
class WeeklyRecapCubit extends Cubit<WeeklyRecapState> {
  final GetWeeklyRecapUseCase _recap;
  final GetListeningCalendarUseCase _calendar;
  final DateTime Function() _now;

  WeeklyRecapCubit({
    required GetWeeklyRecapUseCase recap,
    required GetListeningCalendarUseCase calendar,
    DateTime Function()? now,
  }) : _recap = recap,
       _calendar = calendar,
       _now = now ?? DateTime.now,
       super(WeeklyRecapState(month: _monthOf((now ?? DateTime.now)())));

  static DateTime _monthOf(DateTime t) => DateTime(t.year, t.month);

  Future<void> load() async {
    final now = _now();
    final month = _monthOf(now);
    final (recap, days) = await (_recap(now: now), _calendar(month)).wait;
    if (isClosed) return;
    emit(
      WeeklyRecapState(
        loading: false,
        month: month,
        recap: recap.getOrElse(() => null),
        activeDays: days.getOrElse(() => const {}),
      ),
    );
  }
}
