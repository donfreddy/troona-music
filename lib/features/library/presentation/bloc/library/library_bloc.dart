import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:troona/core/utils/sort_key.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/services/library_grouping.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_use_case.dart';
import 'package:troona/features/library/domain/use_cases/scan_library_use_case.dart';
import 'package:troona/services/metadata/artist_artwork_prefetch_service.dart';
import 'package:troona/services/scanner/media_scanner_service.dart';

part 'library_event.dart';
part 'library_state.dart';
part 'library_view.dart';

final class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final ScanLibraryUseCase _scanLibrary;
  final GetTracksUseCase _getTracks;
  final ArtistArtworkPrefetchService? _prefetchService;

  StreamSubscription<ScanProgress>? _scanSub;

  LibraryBloc({
    required ScanLibraryUseCase scanLibrary,
    required GetTracksUseCase getTracks,
    ArtistArtworkPrefetchService? prefetchService,
  }) : _scanLibrary = scanLibrary,
       _getTracks = getTracks,
       _prefetchService = prefetchService,
       super(const LibraryInitial()) {
    on<LibraryBootstrapRequested>(
      _onBootstrapRequested,
      transformer: droppable(),
    );
    on<LibraryScanRequested>(_onScanRequested, transformer: droppable());
    on<LibraryRefreshRequested>(_onRefreshRequested, transformer: droppable());
    on<LibrarySearchChanged>(_onSearchChanged, transformer: sequential());
    on<LibraryFilterChanged>(_onFilterChanged);
    on<LibrarySortChanged>(_onSortChanged);

    on<_ScanProgressReceived>(_onScanProgress, transformer: concurrent());
    on<_ScanFailed>(_onScanFailed, transformer: concurrent());
    on<_TracksLoaded>(_onTracksLoaded, transformer: concurrent());
  }

  // ══════════════════════════════════════════════════════════
  // SCAN
  // ══════════════════════════════════════════════════════════

  Future<void> _onBootstrapRequested(
    LibraryBootstrapRequested event,
    Emitter<LibraryState> emit,
  ) async {
    if (state is! LibraryInitial) return;

    final cached = await _readLoadedState();
    if (cached != null) {
      emit(cached);
      if (cached.allArtists.isNotEmpty) {
        unawaited(
          _prefetchService?.prefetchArtists(
            cached.allArtists.take(40).toList(),
          ),
        );
      }
    }

    add(const LibraryScanRequested());
  }

  Future<void> _onScanRequested(
    LibraryScanRequested event,
    Emitter<LibraryState> emit,
  ) async {
    // Cancel a previous scan if still running
    await _cancelScan();

    // Keep the cached data visible during the scan
    final cached = state is LibraryLoaded ? state as LibraryLoaded : null;

    emit(
      LibraryScanning(
        progress: const ScanProgress(phase: ScanPhase.scanning, progress: 0),
        cached: cached,
      ),
    );

    final result = await _scanLibrary();

    result.fold((failure) => add(_ScanFailed(failure.message)), (stream) {
      _scanSub = stream.listen(
        (progress) => add(_ScanProgressReceived(progress)),
        onError: (e) => add(_ScanFailed(e.toString())),
        onDone: () {
          // Scan finished: load the data from Isar
          add(
            const _ScanProgressReceived(
              ScanProgress(phase: ScanPhase.done, progress: 1),
            ),
          );
        },
      );
    });
  }

  Future<void> _onRefreshRequested(
    LibraryRefreshRequested event,
    Emitter<LibraryState> emit,
  ) => _onScanRequested(const LibraryScanRequested(), emit);

  Future<void> _onScanProgress(
    _ScanProgressReceived event,
    Emitter<LibraryState> emit,
  ) async {
    if (state is! LibraryScanning) return;
    final scanning = state as LibraryScanning;

    if (event.progress.phase == ScanPhase.done) {
      // Scan finished: load everything from the Isar cache
      await _loadFromCache(emit);
      return;
    }

    emit(LibraryScanning(progress: event.progress, cached: scanning.cached));
  }

  Future<void> _onScanFailed(
    _ScanFailed event,
    Emitter<LibraryState> emit,
  ) async {
    final lastLoaded = switch (state) {
      LibraryScanning(:final cached) => cached,
      LibraryLoaded() => state as LibraryLoaded,
      _ => null,
    };
    emit(LibraryError(message: event.message, lastLoaded: lastLoaded));
  }

  // ══════════════════════════════════════════════════════════
  // LOADING FROM ISAR
  // ══════════════════════════════════════════════════════════

  Future<void> _loadFromCache(Emitter<LibraryState> emit) async {
    // A rescan must not reset the user's filter, sort or query.
    final loaded = await _readLoadedState(view: _loadedSnapshotOf(state));
    if (loaded == null) {
      emit(const LibraryError(message: 'Unable to load cached library.'));
      return;
    }

    emit(loaded);
    if (loaded.allArtists.isNotEmpty) {
      unawaited(
        _prefetchService?.prefetchArtists(loaded.allArtists.take(40).toList()),
      );
    }
  }

  /// One read of the tracks; albums and artists are derived from it, so the
  /// three lists always describe the same snapshot.
  Future<LibraryLoaded?> _readLoadedState({LibraryLoaded? view}) async {
    final result = await _getTracks();
    final tracks = result.fold((_) => null, (t) => t);
    if (tracks == null) return null;
    return _loaded(
      tracks: tracks,
      albums: LibraryGrouping.albumsOf(tracks),
      artists: LibraryGrouping.artistsOf(tracks),
      view: view,
    );
  }

  LibraryLoaded _loaded({
    required List<Track> tracks,
    required List<Album> albums,
    required List<Artist> artists,
    LibraryLoaded? view,
  }) {
    final query = view?.searchQuery ?? '';
    final filter = view?.filter ?? LibraryFilter.all;
    final sort = view?.sort ?? LibrarySort.title;
    final visible = applyLibraryView(
      tracks: tracks,
      albums: albums,
      artists: artists,
      query: query,
      filter: filter,
      sort: sort,
    );
    return LibraryLoaded(
      allTracks: tracks,
      allAlbums: albums,
      allArtists: artists,
      visibleTracks: visible.$1,
      visibleAlbums: visible.$2,
      visibleArtists: visible.$3,
      searchQuery: query,
      filter: filter,
      sort: sort,
    );
  }

  void _onTracksLoaded(_TracksLoaded event, Emitter<LibraryState> emit) {
    emit(
      _loaded(
        tracks: event.tracks,
        albums: event.albums,
        artists: event.artists,
        view: _loadedSnapshotOf(state),
      ),
    );

    if (event.artists.isNotEmpty) {
      unawaited(
        _prefetchService?.prefetchArtists(event.artists.take(40).toList()),
      );
    }
  }

  // ══════════════════════════════════════════════════════════
  // SEARCH / FILTER / SORT: synchronous, in memory
  // ══════════════════════════════════════════════════════════

  void _onSearchChanged(
    LibrarySearchChanged event,
    Emitter<LibraryState> emit,
  ) {
    final current = _loadedSnapshotOf(state);
    if (current == null) return;

    // Recomputed in memory; the sequential() transformer keeps the order
    final visible = applyLibraryView(
      tracks: current.allTracks,
      albums: current.allAlbums,
      artists: current.allArtists,
      query: event.query,
      filter: current.filter,
      sort: current.sort,
    );

    _emitUpdatedLoadedSnapshot(
      emit,
      current.copyWith(
        searchQuery: event.query,
        visibleTracks: visible.$1,
        visibleAlbums: visible.$2,
        visibleArtists: visible.$3,
      ),
    );
  }

  void _onFilterChanged(
    LibraryFilterChanged event,
    Emitter<LibraryState> emit,
  ) {
    final current = _loadedSnapshotOf(state);
    if (current == null) return;

    final visible = applyLibraryView(
      tracks: current.allTracks,
      albums: current.allAlbums,
      artists: current.allArtists,
      query: current.searchQuery,
      filter: event.filter,
      sort: current.sort,
    );

    _emitUpdatedLoadedSnapshot(
      emit,
      current.copyWith(
        filter: event.filter,
        visibleTracks: visible.$1,
        visibleAlbums: visible.$2,
        visibleArtists: visible.$3,
      ),
    );
  }

  void _onSortChanged(LibrarySortChanged event, Emitter<LibraryState> emit) {
    final current = _loadedSnapshotOf(state);
    if (current == null) return;

    final visible = applyLibraryView(
      tracks: current.allTracks,
      albums: current.allAlbums,
      artists: current.allArtists,
      query: current.searchQuery,
      filter: current.filter,
      sort: event.sort,
    );

    _emitUpdatedLoadedSnapshot(
      emit,
      current.copyWith(
        sort: event.sort,
        visibleTracks: visible.$1,
        visibleAlbums: visible.$2,
        visibleArtists: visible.$3,
      ),
    );
  }

  LibraryLoaded? _loadedSnapshotOf(LibraryState state) => switch (state) {
    LibraryLoaded() => state,
    LibraryScanning(:final cached?) => cached,
    LibraryError(:final lastLoaded?) => lastLoaded,
    _ => null,
  };

  void _emitUpdatedLoadedSnapshot(
    Emitter<LibraryState> emit,
    LibraryLoaded updated,
  ) {
    switch (state) {
      case LibraryLoaded():
        emit(updated);
      case LibraryScanning(:final progress):
        emit(LibraryScanning(progress: progress, cached: updated));
      case LibraryError(:final message):
        emit(LibraryError(message: message, lastLoaded: updated));
      default:
        emit(updated);
    }
  }

  // ══════════════════════════════════════════════════════════
  // LIFECYCLE
  // ══════════════════════════════════════════════════════════

  Future<void> _cancelScan() async {
    _scanLibrary.cancel();
    await _scanSub?.cancel();
    _scanSub = null;
  }

  @override
  Future<void> close() async {
    await _cancelScan();
    return super.close();
  }
}
