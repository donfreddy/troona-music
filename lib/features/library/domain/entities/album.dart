import 'package:troona/features/library/domain/entities/artist_credit.dart';

class Album {
  final String id;
  final String name;

  /// Its artists' names joined (`LibraryGrouping`), '' for none.
  final String artist;

  /// The first of [credits].
  final int artistId;
  final int trackCount;
  final String? artworkPath;

  /// A single, not an album: named after one of its few songs
  /// (`SingleRelease`).
  final bool isSingle;

  /// The year its songs were released, when their tags say.
  final int? year;

  /// Each artist the album is by, each with their own page; none for a
  /// compilation. An album read without its songs knows only [artist]
  /// and [artistId].
  List<ArtistCredit> get credits =>
      _credits ??
      [if (artist.isNotEmpty) ArtistCredit(id: artistId, name: artist)];
  final List<ArtistCredit>? _credits;

  const Album({
    required this.id,
    required this.name,
    required this.artist,
    required this.artistId,
    required this.trackCount,
    this.artworkPath,
    this.isSingle = false,
    this.year,
    List<ArtistCredit>? credits,
  }) : _credits = credits;

  Album copyWith({String? artworkPath}) {
    return Album(
      id: id,
      name: name,
      artist: artist,
      artistId: artistId,
      trackCount: trackCount,
      artworkPath: artworkPath ?? this.artworkPath,
      isSingle: isSingle,
      year: year,
      credits: _credits,
    );
  }
}
