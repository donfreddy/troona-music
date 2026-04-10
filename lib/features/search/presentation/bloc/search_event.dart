part of 'search_bloc.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();
  @override
  List<Object?> get props => [];
}

final class SearchTextChanged extends SearchEvent {
  final String query;
  const SearchTextChanged(this.query);
  @override
  List<Object?> get props => [query];
}

final class SearchClearRequested extends SearchEvent {}
