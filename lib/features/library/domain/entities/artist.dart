class Artist {
  final String id;
  final String name;

  /// Their own albums: the ones they are credited on for every song, not
  /// the ones they only appear on.
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
