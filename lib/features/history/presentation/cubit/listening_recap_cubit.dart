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

  /// The last read failed.
  final bool failed;

  /// The first day the history covers, from the last read that knew it:
  /// kept through a failure, so the arrows still work.
  final int? historyStart;

  const ListeningRecapState({
    required this.period,
    required this.firstDay,
    required this.today,
    this.loading = true,
    this.recap,
    this.failed = false,
    this.historyStart,
  });

  /// [recap] is the span [period] and [firstDay] name, not the one before.
  bool get isShown =>
      recap != null && recap!.period == period && recap!.firstDay == firstDay;

  /// The span holds today: it is still being listened to.
  bool get isCurrent => period.rangeOf(today).$1 == firstDay;

  /// The span just before the current one: "last week", "last month".
  bool get isPrevious => period.shift(period.rangeOf(today).$1, -1) == firstDay;

  /// An earlier span may hold plays: the history began before this one.
  bool get canGoBack {
    final start = historyStart;
    return start != null && start < firstDay;
  }

  bool get canGoForward => !isCurrent;

  ListeningRecapState copyWith({
    RecapPeriod? period,
    int? firstDay,
    int? today,
    bool? loading,
    ListeningRecap? Function()? recap,
    bool? failed,
    int? historyStart,
  }) => ListeningRecapState(
    period: period ?? this.period,
    firstDay: firstDay ?? this.firstDay,
    today: today ?? this.today,
    loading: loading ?? this.loading,
    recap: recap != null ? recap() : this.recap,
    failed: failed ?? this.failed,
    historyStart: historyStart ?? this.historyStart,
  );

  @override
  List<Object?> get props => [
    period,
    firstDay,
    today,
    loading,
    recap,
    failed,
    historyStart,
  ];
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
    firstDay: _defaultFirstDay(RecapPeriod.week, ListeningDay.of(now)),
    today: ListeningDay.of(now),
  );

  /// The first day of the span each period opens on, as of [today]: last
  /// week, the one the Home card tells about; this month.
  static int _defaultFirstDay(RecapPeriod period, int today) =>
      period.rangeOf(switch (period) {
        RecapPeriod.week => today - 7,
        RecapPeriod.month => today,
      }).$1;

  /// Reads the span the period opens on, as of now: Home refreshes its
  /// card with it, so last week moves on on Mondays.
  Future<void> load() => _show(
    state.period,
    _defaultFirstDay(state.period, ListeningDay.of(_now())),
  );

  /// Catches up with a new day (the app comes back after midnight): the
  /// span a period opens on moves on with it; another span stays, with
  /// today moved, so the arrows reach the new week or month.
  Future<void> refreshClock() {
    final today = ListeningDay.of(_now());
    if (today == state.today) return Future.value();
    if (state.firstDay == _defaultFirstDay(state.period, state.today)) {
      return load();
    }
    emit(state.copyWith(today: today));
    return Future.value();
  }

  /// Switches to [period], on the span it opens on.
  Future<void> showPeriod(RecapPeriod period) {
    if (period == state.period) return Future.value();
    return _show(period, _defaultFirstDay(period, ListeningDay.of(_now())));
  }

  /// Moves [steps] spans away: back when negative. Never past today.
  Future<void> step(int steps) {
    final period = state.period;
    final first = period.shift(state.firstDay, steps);
    if (first > ListeningDay.of(_now())) return Future.value();
    return _show(period, first);
  }

  Future<void> _show(RecapPeriod period, int first) async {
    final read = ++_read;
    emit(
      state.copyWith(
        period: period,
        firstDay: first,
        // The page may stay open past midnight.
        today: ListeningDay.of(_now()),
        loading: true,
      ),
    );
    final result = await _recap(period, first, today: state.today);
    if (isClosed || read != _read) return;
    final recap = result.fold((_) => null, (r) => r);
    emit(
      state.copyWith(
        loading: false,
        recap: () => recap,
        failed: recap == null,
        historyStart: recap?.historyStart,
      ),
    );
  }
}
