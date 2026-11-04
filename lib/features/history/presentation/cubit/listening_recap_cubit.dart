import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/history/domain/entities/listening_recap.dart';
import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/history/domain/use_cases/get_listening_recap_use_case.dart';

final class ListeningRecapState extends Equatable {
  final RecapPeriod period;

  /// The first day of the span shown (`ListeningDay` key). It moves as soon
  /// as the span changes; [recap] follows once read.
  final int firstDay;

  /// Today, as a `ListeningDay` key: no span after it.
  final int today;

  final bool loading;

  /// The span's recap; null before the first read and after a failure. It
  /// may still be the previous span's while [loading].
  final ListeningRecap? recap;

  const ListeningRecapState({
    required this.period,
    required this.firstDay,
    required this.today,
    this.loading = true,
    this.recap,
  });

  /// The span holds today: it is still being listened to.
  bool get isCurrent => period.rangeOf(today).$1 == firstDay;

  /// The span just before the current one: "last week", "last month".
  bool get isPrevious => period.shift(period.rangeOf(today).$1, -1) == firstDay;

  /// An earlier span may hold plays: the history began before this one.
  bool get canGoBack {
    final start = recap?.historyStart;
    return start != null && start < firstDay;
  }

  bool get canGoForward => !isCurrent;

  ListeningRecapState copyWith({
    RecapPeriod? period,
    int? firstDay,
    bool? loading,
    ListeningRecap? Function()? recap,
  }) => ListeningRecapState(
    period: period ?? this.period,
    firstDay: firstDay ?? this.firstDay,
    today: today,
    loading: loading ?? this.loading,
    recap: recap != null ? recap() : this.recap,
  );

  @override
  List<Object?> get props => [period, firstDay, today, loading, recap];
}

/// The recap of one week or month, last week first: the Home card and the
/// recap page, which moves between spans. A read failure shows as no
/// recap: the card is a bonus, not worth an error.
class ListeningRecapCubit extends Cubit<ListeningRecapState> {
  final GetListeningRecapUseCase _recap;
  final DateTime Function() _now;

  /// Bumped by each read: a slow answer for a span already left is dropped.
  int _read = 0;

  ListeningRecapCubit({
    required GetListeningRecapUseCase recap,
    DateTime Function()? now,
  }) : _recap = recap,
       _now = now ?? DateTime.now,
       super(_initial((now ?? DateTime.now)()));

  static ListeningRecapState _initial(DateTime now) => ListeningRecapState(
    period: RecapPeriod.week,
    firstDay: RecapPeriod.week
        .rangeOf(GetListeningRecapUseCase.lastWeekOf(now))
        .$1,
    today: ListeningDay.of(now),
  );

  /// The span each period opens on: last week, the one the Home card
  /// tells about; this month, the one the calendar used to show.
  static int _defaultDayOf(RecapPeriod period, DateTime now) =>
      switch (period) {
        RecapPeriod.week => GetListeningRecapUseCase.lastWeekOf(now),
        RecapPeriod.month => ListeningDay.of(now),
      };

  /// Reads the span shown again, or last week on the first call.
  Future<void> load() => _show(state.period, state.firstDay);

  /// Switches to [period], on the span it opens on.
  Future<void> showPeriod(RecapPeriod period) {
    if (period == state.period) return Future.value();
    final first = period.rangeOf(_defaultDayOf(period, _now())).$1;
    return _show(period, first);
  }

  /// Moves [steps] spans away: back when negative. Never past today.
  Future<void> step(int steps) {
    final period = state.period;
    final first = period.shift(state.firstDay, steps);
    if (first > state.today) return Future.value();
    return _show(period, first);
  }

  Future<void> _show(RecapPeriod period, int first) async {
    final read = ++_read;
    emit(state.copyWith(period: period, firstDay: first, loading: true));
    final result = await _recap(period, first);
    if (isClosed || read != _read) return;
    emit(
      state.copyWith(
        loading: false,
        recap: () => result.fold((_) => null, (r) => r),
      ),
    );
  }
}
