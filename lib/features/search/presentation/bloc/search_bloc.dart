import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:troona/features/search/domain/entities/search_result.dart';
import 'package:troona/features/search/domain/repositories/search_repository.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository _repo;

  SearchBloc({required SearchRepository repo})
    : _repo = repo,
      super(SearchInitial()) {
    on<SearchTextChanged>(
      _onTextChanged,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 300))
          .switchMap(mapper),
    );
    on<SearchClearRequested>(_onClearRequested);
  }

  Future<void> _onTextChanged(
    SearchTextChanged event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());

    final result = await _repo.search(event.query);

    result.fold(
      (f) => emit(SearchError(f.message)),
      (searchResult) => emit(SearchLoaded(searchResult, event.query)),
    );
  }

  void _onClearRequested(
    SearchClearRequested event,
    Emitter<SearchState> emit,
  ) {
    emit(SearchInitial());
  }
}
