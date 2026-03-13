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
