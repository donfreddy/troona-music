final class Playlist {
  final String id;
  final String name;
  final List<String> trackIds; // IDs des pistes dans la playlist
  final String? artworkPath;

  const Playlist({
    required this.id,
    required this.name,
    this.trackIds = const [],
    this.artworkPath,
  });
}
