part of 'library_bloc.dart';

/// Filtered and sorted lists for the Library page. Pure: the inputs are never
/// mutated, so the full lists keep their order and every result is a new
/// list (Equatable states then compare unequal and the page rebuilds).
@visibleForTesting
(List<Track>, List<Album>, List<Artist>) applyLibraryView({
  required List<Track> tracks,
  required List<Album> albums,
  required List<Artist> artists,
  required String query,
  required LibraryFilter filter,
  required LibrarySort sort,
}) {
  final q = query.toLowerCase().trim();
  bool has(String s) => s.toLowerCase().contains(q);

  var visibleTracks =
      filter == LibraryFilter.all || filter == LibraryFilter.tracks
      ? [
          for (final t in tracks)
            if (q.isEmpty || has(t.title) || has(t.artist) || has(t.album)) t,
        ]
      : <Track>[];
  var visibleAlbums =
      filter == LibraryFilter.all || filter == LibraryFilter.albums
      ? [
          for (final a in albums)
            if (q.isEmpty || has(a.name) || has(a.artist)) a,
        ]
      : <Album>[];
  var visibleArtists =
      filter == LibraryFilter.all || filter == LibraryFilter.artists
      ? [
          for (final a in artists)
            if (q.isEmpty || has(a.name)) a,
        ]
      : <Artist>[];

  int text(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

  switch (sort) {
    case LibrarySort.title:
      visibleTracks.sort((a, b) => text(a.title, b.title));
      visibleAlbums.sort((a, b) => text(a.name, b.name));
      visibleArtists.sort((a, b) => text(a.name, b.name));
    case LibrarySort.artist:
      visibleTracks.sort(
        (a, b) => _then(text(a.artist, b.artist), text(a.title, b.title)),
      );
      visibleAlbums.sort(
        (a, b) => _then(text(a.artist, b.artist), text(a.name, b.name)),
      );
      visibleArtists.sort((a, b) => text(a.name, b.name));
    case LibrarySort.album:
      visibleTracks.sort(
        (a, b) => _then(
          text(a.album, b.album),
          (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0),
        ),
      );
      visibleAlbums.sort((a, b) => text(a.name, b.name));
      visibleArtists.sort((a, b) => text(a.name, b.name));
    case LibrarySort.dateAdded:
      // Newest first; songs without a date go last.
      visibleTracks.sort(
        (a, b) => _then(
          (b.dateAdded?.millisecondsSinceEpoch ?? 0).compareTo(
            a.dateAdded?.millisecondsSinceEpoch ?? 0,
          ),
          text(a.title, b.title),
        ),
      );
      visibleAlbums.sort((a, b) => text(a.name, b.name));
      visibleArtists.sort((a, b) => text(a.name, b.name));
  }

  return (visibleTracks, visibleAlbums, visibleArtists);
}

int _then(int first, int second) => first != 0 ? first : second;
