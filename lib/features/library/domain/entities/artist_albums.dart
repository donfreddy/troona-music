import 'package:troona/features/library/domain/entities/album.dart';

/// The albums of the library that hold songs by one artist.
final class ArtistAlbums {
  /// Their own albums: they are credited on every song.
  final List<Album> own;

  /// The albums they appear on: credited on some songs only, such as a
  /// guest verse on someone else's album, or a compilation.
  final List<Album> appearsOn;

  const ArtistAlbums({this.own = const [], this.appearsOn = const []});

  /// [own] then [appearsOn].
  List<Album> get all => [...own, ...appearsOn];
}
