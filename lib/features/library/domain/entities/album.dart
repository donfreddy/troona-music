class Album {
  final String id;
  final String name;
  final String artist;
  final int artistId;
  final int trackCount;
  final String? artworkPath;

  /// A single, not an album: named after one of its few songs
  /// (`SingleRelease`).
  final bool isSingle;

  const Album({
    required this.id,
    required this.name,
    required this.artist,
    required this.artistId,
    required this.trackCount,
    this.artworkPath,
    this.isSingle = false,
  });

  Album copyWith({String? artworkPath}) {
    return Album(
      id: id,
      name: name,
      artist: artist,
      artistId: artistId,
      trackCount: trackCount,
      artworkPath: artworkPath ?? this.artworkPath,
      isSingle: isSingle,
    );
  }
}
