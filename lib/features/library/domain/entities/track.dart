class Track {
  String id;
  String title;
  String artist;
  int artistId;
  String album;
  int albumId;
  String? genre;
  int? genreId;
  int? trackNumber;
  String path;
  String uri;
  int size;
  int durationMs;
  String fileName;
  String? artworkPath;
  int? year;
  String? composer;
  DateTime? dateAdded;
  DateTime? dateModified;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistId,
    required this.album,
    required this.albumId,
    this.genre,
    this.genreId,
    this.trackNumber,
    required this.path,
    required this.uri,
    required this.size,
    required this.durationMs,
    required this.fileName,
    this.year,
    this.composer,
    this.artworkPath,
    this.dateAdded,
    this.dateModified,
  });
}
