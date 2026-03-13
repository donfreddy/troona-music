import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/use_cases/get_albums_use_case.dart';
import 'package:troona/features/library/domain/use_cases/get_artists_use_case.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_use_case.dart';
import 'package:troona/features/library/domain/use_cases/scan_library_use_case.dart';
import 'package:troona/services/scanner/media_scanner_service.dart';

part 'library_event.dart';
part 'library_state.dart';

final class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final ScanLibraryUseCase _scanLibrary;
  final GetTracksUseCase _getTracks;
  final GetAlbumsUseCase _getAlbums;
  final GetArtistsUseCase _getArtists;

  StreamSubscription<ScanProgress>? _scanSub;

  LibraryBloc({
    required ScanLibraryUseCase scanLibrary,
    required GetTracksUseCase getTracks,
    required GetAlbumsUseCase getAlbums,
    required GetArtistsUseCase getArtists,
  }) : _scanLibrary = scanLibrary,
       _getTracks = getTracks,
       _getAlbums = getAlbums,
       _getArtists = getArtists,
       super(const LibraryInitial()) {
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

  Future<void> _onScanRequested(
    LibraryScanRequested event,
    Emitter<LibraryState> emit,
  ) async {
    // Annule un scan précédent si toujours en cours
    await _cancelScan();

    // Garde les données en cache visibles pendant le scan
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
          // Le scan est terminé — charge les données depuis Isar
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
      // Scan terminé — charge tout depuis le cache Isar
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
  // CHARGEMENT DEPUIS ISAR
  // ══════════════════════════════════════════════════════════

  Future<void> _loadFromCache(Emitter<LibraryState> emit) async {
    // Charge tracks, albums, artists en parallèle
    final results = await Future.wait([
      _getTracks(),
      _getAlbums(),
      _getArtists(),
    ]);

    final tracksResult = results[0] as Either<Failure, List<Track>>;
    final albumsResult = results[1] as Either<Failure, List<Album>>;
    final artistsResult = results[2] as Either<Failure, List<Artist>>;

    // Si l'un des trois échoue on émet une erreur
    if (tracksResult.isLeft() ||
        albumsResult.isLeft() ||
        artistsResult.isLeft()) {
      final msg =
          tracksResult.fold((f) => f.message, (_) => '') +
          albumsResult.fold((f) => f.message, (_) => '') +
          artistsResult.fold((f) => f.message, (_) => '');
      emit(LibraryError(message: msg));
      return;
    }

    final tracks = tracksResult.getOrElse(() => []);
    final albums = albumsResult.getOrElse(() => []);
    final artists = artistsResult.getOrElse(() => []);

    add(_TracksLoaded(tracks, albums, artists));
  }

  void _onTracksLoaded(_TracksLoaded event, Emitter<LibraryState> emit) {
    // État courant : récupère les préférences filter/sort si déjà Loaded
    final (filter, sort, query) = switch (state) {
      LibraryLoaded(:final filter, :final sort, :final searchQuery) => (
        filter,
        sort,
        searchQuery,
      ),
      _ => (LibraryFilter.all, LibrarySort.title, ''),
    };

    final visible = _applyFilterAndSort(
      tracks: event.tracks,
      albums: event.albums,
      artists: event.artists,
      query: query,
      filter: filter,
      sort: sort,
    );

    emit(
      LibraryLoaded(
        allTracks: event.tracks,
        allAlbums: event.albums,
        allArtists: event.artists,
        visibleTracks: visible.$1,
        visibleAlbums: visible.$2,
        visibleArtists: visible.$3,
        searchQuery: query,
        filter: filter,
        sort: sort,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SEARCH / FILTER / SORT — calcul synchrone, pas d'async
  // ══════════════════════════════════════════════════════════

  void _onSearchChanged(
    LibrarySearchChanged event,
    Emitter<LibraryState> emit,
  ) {
    if (state is! LibraryLoaded) return;
    final current = state as LibraryLoaded;

    // Recalcule en mémoire — le transformer sequential() garantit l'ordre
    final visible = _applyFilterAndSort(
      tracks: current.allTracks,
      albums: current.allAlbums,
      artists: current.allArtists,
      query: event.query,
      filter: current.filter,
      sort: current.sort,
    );

    emit(
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
    if (state is! LibraryLoaded) return;
    final current = state as LibraryLoaded;

    final visible = _applyFilterAndSort(
      tracks: current.allTracks,
      albums: current.allAlbums,
      artists: current.allArtists,
      query: current.searchQuery,
      filter: event.filter,
      sort: current.sort,
    );

    emit(
      current.copyWith(
        filter: event.filter,
        visibleTracks: visible.$1,
        visibleAlbums: visible.$2,
        visibleArtists: visible.$3,
      ),
    );
  }

  void _onSortChanged(LibrarySortChanged event, Emitter<LibraryState> emit) {
    if (state is! LibraryLoaded) return;
    final current = state as LibraryLoaded;

    final visible = _applyFilterAndSort(
      tracks: current.allTracks,
      albums: current.allAlbums,
      artists: current.allArtists,
      query: current.searchQuery,
      filter: current.filter,
      sort: event.sort,
    );

    emit(
      current.copyWith(
        sort: event.sort,
        visibleTracks: visible.$1,
        visibleAlbums: visible.$2,
        visibleArtists: visible.$3,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // FILTRE + TRI — pur, sans side effects
  // ══════════════════════════════════════════════════════════

  (List<Track>, List<Album>, List<Artist>) _applyFilterAndSort({
    required List<Track> tracks,
    required List<Album> albums,
    required List<Artist> artists,
    required String query,
    required LibraryFilter filter,
    required LibrarySort sort,
  }) {
    final q = query.toLowerCase().trim();

    // ── Filtrage textuel ────────────────────────────────────
    var filteredTracks = q.isEmpty
        ? tracks
        : tracks
              .where(
                (t) =>
                    t.title.toLowerCase().contains(q) ||
                    t.artist.toLowerCase().contains(q) ||
                    t.album.toLowerCase().contains(q),
              )
              .toList();

    var filteredAlbums = q.isEmpty
        ? albums
        : albums
              .where(
                (a) =>
                    a.name.toLowerCase().contains(q) ||
                    a.artist.toLowerCase().contains(q),
              )
              .toList();

    var filteredArtists = q.isEmpty
        ? artists
        : artists.where((a) => a.name.toLowerCase().contains(q)).toList();

    switch (filter) {
      case LibraryFilter.tracks:
        filteredAlbums = <Album>[];
        filteredArtists = <Artist>[];
        break;
      case LibraryFilter.albums:
        filteredTracks = <Track>[];
        filteredArtists = <Artist>[];
        break;
      case LibraryFilter.artists:
        filteredTracks = <Track>[];
        filteredAlbums = <Album>[];
        break;
      case LibraryFilter.all:
        break;
    }

    // ── Tri ─────────────────────────────────────────────────
    switch (sort) {
      case LibrarySort.title:
        filteredTracks.sort((a, b) => a.title.compareTo(b.title));
        filteredAlbums.sort((a, b) => a.name.compareTo(b.name));
        filteredArtists.sort((a, b) => a.name.compareTo(b.name));
        break;
      case LibrarySort.artist:
        filteredTracks.sort((a, b) => a.artist.compareTo(b.artist));
        filteredAlbums.sort((a, b) => a.artist.compareTo(b.artist));
        filteredArtists.sort((a, b) => a.name.compareTo(b.name));
        break;
      case LibrarySort.album:
        filteredTracks.sort((a, b) => a.album.compareTo(b.album));
        filteredAlbums.sort((a, b) => a.name.compareTo(b.name));
        break;
      case LibrarySort.dateAdded:
        // Isar retourne déjà dans l'ordre d'insertion — pas de tri nécessaire
        break;
    }

    return (filteredTracks, filteredAlbums, filteredArtists);
  }

  // ══════════════════════════════════════════════════════════
  // LIFECYCLE
  // ══════════════════════════════════════════════════════════

  Future<void> _cancelScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
  }

  @override
  Future<void> close() async {
    await _cancelScan();
    return super.close();
  }
}
