import 'package:troona/features/library/domain/entities/album.dart';

/// The albums of the library that hold songs by one artist.
final class ArtistAlbums {
  /// Their own albums: they are credited on every song.
  final List<Album> own;

  /// Their own singles (`Album.isSingle`).
  final List<Album> singles;

  /// The albums and singles they appear on: credited on some songs only,
  /// such as a guest verse on someone else's album, or a compilation.
  final List<Album> appearsOn;

  const ArtistAlbums({
    this.own = const [],
    this.singles = const [],
    this.appearsOn = const [],
  });

  /// [own], [singles], then [appearsOn].
  List<Album> get all => [...own, ...singles, ...appearsOn];

  /// Their releases: [own], then [singles].
  List<Album> get releases => [...own, ...singles];

  /// Releases needed for Latest release: with fewer, its cover is a screen
  /// away at most, in the section below.
  static const latestFrom = 4;

  /// With fewer releases than this, their albums and singles make one
  /// section: three titles over three covers is structure, not content.
  static const discographyBelow = 5;

  /// Whether [own] and [singles] show as one Discography.
  bool get oneDiscography =>
      own.isNotEmpty &&
      singles.isNotEmpty &&
      own.length + singles.length < discographyBelow;

  /// Their newest album or single, by year. None when no release has a
  /// year (MediaStore often reads none), nor with fewer than [latestFrom].
  Album? get latest {
    final releases = this.releases;
    if (releases.length < latestFrom) return null;
    Album? newest;
    for (final album in releases) {
      final year = album.year;
      if (year != null && year > (newest?.year ?? 0)) newest = album;
    }
    return newest;
  }
}
