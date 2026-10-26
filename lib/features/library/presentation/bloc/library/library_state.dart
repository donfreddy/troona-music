part of 'library_bloc.dart';

sealed class LibraryState extends Equatable {
  const LibraryState();

  @override
  List<Object?> get props => [];
}

/// First launch: no scan has run yet.
final class LibraryInitial extends LibraryState {
  const LibraryInitial();
}

/// Scan in progress, possibly over cached data.
final class LibraryScanning extends LibraryState {
  final ScanProgress progress;
  final LibraryLoaded? cached; // previous data, shown during the scan

  const LibraryScanning({required this.progress, this.cached});

  @override
  List<Object?> get props => [
    progress.phase,
    progress.progress,
    progress.count,
    progress.total,
    cached,
  ];
}

/// Library loaded: the main state.
final class LibraryLoaded extends LibraryState {
  final List<Track> allTracks;
  final List<Album> allAlbums;
  final List<Artist> allArtists;

  // Filtered and sorted view, computed once rather than on every rebuild
  final List<Track> visibleTracks;
  final List<Album> visibleAlbums;
  final List<Artist> visibleArtists;

  final String searchQuery;
  final LibraryFilter filter;
  final LibrarySort sort;

  const LibraryLoaded({
    required this.allTracks,
    required this.allAlbums,
    required this.allArtists,
    required this.visibleTracks,
    required this.visibleAlbums,
    required this.visibleArtists,
    this.searchQuery = '',
    this.filter = LibraryFilter.all,
    this.sort = LibrarySort.title,
  });

  bool get isEmpty => allTracks.isEmpty;
  bool get isFiltered => searchQuery.isNotEmpty || filter != LibraryFilter.all;
  int get totalCount => allTracks.length;

  LibraryLoaded copyWith({
    List<Track>? allTracks,
    List<Album>? allAlbums,
    List<Artist>? allArtists,
    List<Track>? visibleTracks,
    List<Album>? visibleAlbums,
    List<Artist>? visibleArtists,
    String? searchQuery,
    LibraryFilter? filter,
    LibrarySort? sort,
  }) => LibraryLoaded(
    allTracks: allTracks ?? this.allTracks,
    allAlbums: allAlbums ?? this.allAlbums,
    allArtists: allArtists ?? this.allArtists,
    visibleTracks: visibleTracks ?? this.visibleTracks,
    visibleAlbums: visibleAlbums ?? this.visibleAlbums,
    visibleArtists: visibleArtists ?? this.visibleArtists,
    searchQuery: searchQuery ?? this.searchQuery,
    filter: filter ?? this.filter,
    sort: sort ?? this.sort,
  );

  @override
  List<Object?> get props => [
    allTracks,
    allAlbums,
    allArtists,
    visibleTracks,
    visibleAlbums,
    visibleArtists,
    searchQuery,
    filter,
    sort,
  ];
}

/// Recoverable error.
final class LibraryError extends LibraryState {
  final String message;
  final LibraryLoaded? lastLoaded; // cached data to keep showing, if any
  const LibraryError({required this.message, this.lastLoaded});

  @override
  List<Object?> get props => [message, lastLoaded];
}

// ── Enums ─────────────────────────────────────────────────

enum LibraryFilter { all, tracks, albums, artists }

enum LibrarySort { title, artist, album, dateAdded }
