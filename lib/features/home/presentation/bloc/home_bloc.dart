import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:troona/features/home/domain/entities/home_feed.dart';
import 'package:troona/features/home/domain/repositories/home_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _repo;

  HomeBloc({required HomeRepository repo})
    : _repo = repo,
      super(HomeInitial()) {
    on<HomeFeedRequested>(_onFeedRequested, transformer: droppable());
    on<HomeRefreshRequested>(_onFeedRequested, transformer: droppable());
  }

  Future<void> _onFeedRequested(
    HomeEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoaded) emit(const HomeLoading());

    final results = await Future.wait([
      _repo.getFeed(),
      _repo.getTotalTrackCount(),
    ]);

    final feedResult = results[0];
    final countResult = results[1];

    feedResult.fold(
      (f) => emit(HomeError(f.message)),
      (feed) {
        final count = countResult.fold((_) => 0, (c) => c as int);
        emit(HomeLoaded(feed as HomeFeed, totalTracks: count));
      },
    );
  }
}
