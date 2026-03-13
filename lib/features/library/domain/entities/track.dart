class Track {
  int id;
  String title;
  String artist;
  String album;
  Duration durationMs;
  String artworkPath;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationMs,
    required this.artworkPath,
  });
}