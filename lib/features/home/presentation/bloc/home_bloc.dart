import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:troona/features/home/domain/entities/home_feed.dart';
import 'package:troona/features/home/domain/repositories/home_repository.dart';
import 'package:troona/services/metadata/artist_artwork_prefetch_service.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _repo;
  final ArtistArtworkPrefetchService? _prefetchService;
  late final StreamSubscription<void> _feedChangesSub;

  HomeBloc({
    required HomeRepository repo,
    ArtistArtworkPrefetchService? prefetchService,
    Duration refreshDelay = const Duration(milliseconds: 500),
  }) : _repo = repo,
       _prefetchService = prefetchService,
       super(HomeInitial()) {
    on<HomeFeedRequested>(_onFeedRequested, transformer: droppable());
    on<HomeRefreshRequested>(_onFeedRequested, transformer: droppable());
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

    final results = await Future.wait([
      _repo.getFeed(),
      _repo.getTotalTrackCount(),
    ]);

    final feedResult = results[0];
    final countResult = results[1];

    feedResult.fold((f) => emit(HomeError(f.message)), (feed) {
      final homeFeed = feed as HomeFeed;
      final count = countResult.fold((_) => 0, (c) => c as int);
      emit(HomeLoaded(homeFeed, totalTracks: count));

      // Silently prefetch artist portrait photos in background for top artists
      if (homeFeed.yourArtists.isNotEmpty) {
        unawaited(_prefetchService?.prefetchArtists(homeFeed.yourArtists));
      }
    });
  }
}
