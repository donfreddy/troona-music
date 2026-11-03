import 'package:troona/features/library/domain/entities/artist_credit.dart';

class Track {
  String id;
  String title;

  /// The artist tag as written: "Nicki Minaj, Beyoncé".
  String artist;

  /// The first of [credits]: the artist "Go to artist" opens.
  int artistId;

  /// Every artist [artist] names, the first one first. A track built
  /// without them credits its one artist.
  List<ArtistCredit> get credits =>
      _credits ?? [ArtistCredit(id: artistId, name: artist)];
  final List<ArtistCredit>? _credits;
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
    List<ArtistCredit>? credits,
  }) : _credits = (credits == null || credits.isEmpty) ? null : credits;
}
