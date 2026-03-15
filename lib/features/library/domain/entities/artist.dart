class Artist {
  final String id;
  final String name;
  final int albumCount;
  final int trackCount;
  final String? artworkPath;

  const Artist({
    required this.id,
    required this.name,
    required this.albumCount,
    required this.trackCount,
    this.artworkPath,
  });
}
