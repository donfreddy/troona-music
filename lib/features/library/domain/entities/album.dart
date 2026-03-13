class Album {
  final String id;
  final String name;
  final String artist;
  final int trackCount;
  final String? artworkPath;

  const Album({
    required this.id,
    required this.name,
    required this.artist,
    required this.trackCount,
    this.artworkPath,
  });
}
