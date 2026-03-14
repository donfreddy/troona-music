class Track {
  String id;
  String title;
  String artist;
  String album;
  String path;
  String uri;
  int durationMs;
  String? artworkPath;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.path,
    required this.uri,
    required this.durationMs,
    this.artworkPath,
  });
}
