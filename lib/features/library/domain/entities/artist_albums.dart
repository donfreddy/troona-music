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

  /// Their newest album or single, by year. None when no release has a
  /// year (MediaStore often reads none), nor with a single release: its
  /// card is right below.
  Album? get latest {
    final releases = [...own, ...singles];
    if (releases.length < 2) return null;
    Album? newest;
    for (final album in releases) {
      final year = album.year;
      if (year != null && year > (newest?.year ?? 0)) newest = album;
    }
    return newest;
  }
}
