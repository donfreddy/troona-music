part of 'library_bloc.dart';

sealed class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object> get props => [];
}

// ── Commandes utilisateur ────────────────────────────────
final class LibraryBootstrapRequested extends LibraryEvent {
  const LibraryBootstrapRequested();
}

final class LibraryScanRequested extends LibraryEvent {
  const LibraryScanRequested();
}

final class LibraryRefreshRequested extends LibraryEvent {
  const LibraryRefreshRequested();
}

final class LibrarySearchChanged extends LibraryEvent {
  final String query;
  const LibrarySearchChanged(this.query);
}

final class LibraryFilterChanged extends LibraryEvent {
  final LibraryFilter filter; // enum: all, tracks, albums, artists
  const LibraryFilterChanged(this.filter);
}

final class LibrarySortChanged extends LibraryEvent {
  final LibrarySort sort; // enum: title, artist, album, dateAdded
  const LibrarySortChanged(this.sort);
}

// ── Streams internes ─────────────────────────────────────
final class _ScanProgressReceived extends LibraryEvent {
  final ScanProgress progress;
  const _ScanProgressReceived(this.progress);
}

final class _ScanFailed extends LibraryEvent {
  final String message;
  const _ScanFailed(this.message);
}

final class _TracksLoaded extends LibraryEvent {
  final List<Track> tracks;
  final List<Album> albums;
  final List<Artist> artists;
  const _TracksLoaded(this.tracks, this.albums, this.artists);
}
