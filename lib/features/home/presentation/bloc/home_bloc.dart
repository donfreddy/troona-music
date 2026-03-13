import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:troona/features/home/domain/entities/home_feed.dart';
import 'package:troona/features/home/domain/use_cases/get_home_feed_use_case.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetHomeFeedUseCase _getFeed;

  HomeBloc({required GetHomeFeedUseCase getFeed}) : _getFeed = getFeed, super(HomeInitial()) {
    on<HomeFeedRequested>(_onFeedRequested, transformer: droppable());
    on<HomeRefreshRequested>(_onFeedRequested, transformer: droppable());
  }

  Future<void> _onFeedRequested(HomeEvent event, Emitter<HomeState> emit) async {
    // Garde les données visibles pendant le refresh
    if (state is! HomeLoaded) emit(const HomeLoading());

    final result = await _getFeed(NoParams());
    result.fold((f) => emit(HomeError('')), (feed) => emit(HomeLoaded(feed)));
  }
}
