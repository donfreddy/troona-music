part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

final class HomeFeedRequested extends HomeEvent {
  const HomeFeedRequested();
}

final class HomeRefreshRequested extends HomeEvent {
  const HomeRefreshRequested();
}

/// The app came back to the foreground: a feed loaded on another day is
/// reloaded (this week's plays start again on Mondays).
final class HomeResumed extends HomeEvent {
  const HomeResumed();
}
