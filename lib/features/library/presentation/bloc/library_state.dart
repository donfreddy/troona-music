part of 'library_bloc.dart';

sealed class LibraryState extends Equatable {
  const LibraryState();
  
  @override
  List<Object> get props => [];
}

/// Premier lancement — aucun scan jamais effectué
final class LibraryInitial extends LibraryState {
  const LibraryInitial();
}

/// Scan en cours — on a déjà potentiellement des données en cache
final class LibraryScanning extends LibraryState {
  final ScanProgress  progress;
  final LibraryLoaded? cached;   // données précédentes visibles pendant le scan

  const LibraryScanning({
    required this.progress,
    this.cached,
  });

  // Helpers exposés directement aux widgets
  String get phaseLabel => switch (progress.phase) {
    ScanPhase.scanning  => 'Recherche des fichiers audio…',
    ScanPhase.indexing  => 'Indexation… (${progress.count}/${progress.total})',
    ScanPhase.artworks  => 'Chargement des pochettes…',
    ScanPhase.done      => 'Terminé',
  };
}

/// Bibliothèque chargée — état principal
final class LibraryLoaded extends LibraryState {
  final List<Track>  allTracks;
  final List<Album>  allAlbums;
  final List<Artist> allArtists;

  // Vue filtrée / triée — calculée une fois, pas à chaque rebuild
  final List<Track>  visibleTracks;
  final List<Album>  visibleAlbums;
  final List<Artist> visibleArtists;

  final String       searchQuery;
  final LibraryFilter filter;
  final LibrarySort   sort;

  const LibraryLoaded({
    required this.allTracks,
    required this.allAlbums,
    required this.allArtists,
    required this.visibleTracks,
    required this.visibleAlbums,
    required this.visibleArtists,
    this.searchQuery = '',
    this.filter      = LibraryFilter.all,
    this.sort        = LibrarySort.title,
  });

  bool get isEmpty   => allTracks.isEmpty;
  bool get isFiltered => searchQuery.isNotEmpty || filter != LibraryFilter.all;
  int  get totalCount => allTracks.length;

  LibraryLoaded copyWith({
    List<Track>?  allTracks,
    List<Album>?  allAlbums,
    List<Artist>? allArtists,
    List<Track>?  visibleTracks,
    List<Album>?  visibleAlbums,
    List<Artist>? visibleArtists,
    String?       searchQuery,
    LibraryFilter? filter,
    LibrarySort?   sort,
  }) => LibraryLoaded(
    allTracks:      allTracks     ?? this.allTracks,
    allAlbums:      allAlbums     ?? this.allAlbums,
    allArtists:     allArtists    ?? this.allArtists,
    visibleTracks:  visibleTracks ?? this.visibleTracks,
    visibleAlbums:  visibleAlbums ?? this.visibleAlbums,
    visibleArtists: visibleArtists ?? this.visibleArtists,
    searchQuery:    searchQuery   ?? this.searchQuery,
    filter:         filter        ?? this.filter,
    sort:           sort          ?? this.sort,
  );
}

/// Erreur récupérable
final class LibraryError extends LibraryState {
  final String      message;
  final LibraryLoaded? lastLoaded;   // affiche les données en cache si dispo
  const LibraryError({required this.message, this.lastLoaded});
}

// ── Enums ─────────────────────────────────────────────────

enum LibraryFilter { all, tracks, albums, artists }
enum LibrarySort   { title, artist, album, dateAdded }