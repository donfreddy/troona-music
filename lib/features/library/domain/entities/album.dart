class Album {
  final String id;
  final String name;
  final String artist;
  final int artistId;
  final int trackCount;
  final String? artworkPath;

  const Album({
    required this.id,
    required this.name,
    required this.artist,
    required this.artistId,
    required this.trackCount,
    this.artworkPath,
  });

  Album copyWith({String? artworkPath}) {
    return Album(
      id: id,
      name: name,
      artist: artist,
      artistId: artistId,
      trackCount: trackCount,
      artworkPath: artworkPath ?? this.artworkPath,
    );
  }
}
