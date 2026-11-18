import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/home/domain/entities/home_feed.dart';
import 'package:troona/features/home/domain/repositories/home_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _repo;
  final DateTime Function() _now;
  late final StreamSubscription<void> _feedChangesSub;

  /// The day the feed on screen was loaded (`ListeningDay`).
  int? _loadedDay;

  HomeBloc({
    required HomeRepository repo,
    Duration refreshDelay = const Duration(milliseconds: 500),
    DateTime Function()? now,
  }) : _repo = repo,
       _now = now ?? DateTime.now,
       super(HomeInitial()) {
    on<HomeFeedRequested>(_onFeedRequested, transformer: droppable());
    on<HomeRefreshRequested>(_onFeedRequested, transformer: droppable());
    on<HomeResumed>((event, emit) {
      if (_loadedDay == null || _loadedDay == ListeningDay.of(_now())) return;
      add(const HomeRefreshRequested());
    });
    // A recorded play reorders Recently Played; a scan fills an empty Home.
    // A scan writes in batches (songs, then covers): one reload once they
    // settle. The reload keeps the loaded feed on screen (no shimmer).
    _feedChangesSub = _repo.feedChanges
        .debounceTime(refreshDelay)
        .listen((_) => add(const HomeRefreshRequested()));
  }

  @override
  Future<void> close() async {
    await _feedChangesSub.cancel();
    return super.close();
  }

  Future<void> _onFeedRequested(
    HomeEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoaded) emit(const HomeLoading());
    final day = ListeningDay.of(_now());

    final results = await Future.wait([
      _repo.getFeed(),
      _repo.getTotalTrackCount(),
    ]);

    final feedResult = results[0];
    final countResult = results[1];

    feedResult.fold((f) => emit(HomeError(f.message)), (feed) {
      final homeFeed = feed as HomeFeed;
      final count = countResult.fold((_) => 0, (c) => c as int);
      _loadedDay = day;
      emit(HomeLoaded(homeFeed, totalTracks: count));
    });
  }
}
