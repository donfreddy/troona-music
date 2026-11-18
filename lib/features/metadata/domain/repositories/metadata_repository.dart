import 'package:troona/features/metadata/domain/entities/album_online_info.dart';
import 'package:troona/features/metadata/domain/entities/artist_online_info.dart';

abstract interface class MetadataRepository {
  /// Bios and stats (Last.fm), and the photo (Deezer), found through one
  /// of [songTitles], the artist's own songs, most played first: without
  /// them no photo is looked for, since a name alone may find a namesake.
  Future<ArtistOnlineInfo?> getArtistInfo(
    String artistName, {
    List<String> songTitles = const [],
    bool forceRefresh = false,
  });

  Future<AlbumOnlineInfo?> getAlbumInfo(
    String artistName,
    String albumName, {
    bool forceRefresh = false,
  });

  Future<String?> downloadAndCacheArtistArtwork({
    required String artistId,
    required String imageUrl,
  });

  Future<String?> downloadAndCacheAlbumArtwork({
    required String albumId,
    required String imageUrl,
  });

  /// The downloaded photo of [artistId], or null when there is none or the
  /// photos switch was last seen off.
  String? getCachedArtistArtworkPath(String artistId);

  /// Emits an artist id when its photo changes, or [allArtists] after every
  /// artist photo and album cover was removed.
  Stream<String> get onArtistArtworkUpdated;

  static const allArtists = '*';

  /// Deletes every downloaded artist photo and album cover, keeping bios.
  /// Called when the photos switch is turned off.
  Future<void> forgetPhotos();

  /// Downloads the photo of [artistId], found as [getArtistInfo] does.
  Future<String?> prefetchArtistPhoto({
    required String artistId,
    required String artistName,
    required List<String> songTitles,
  });

  Future<int> getMetadataCacheSizeBytes();

  /// Deletes all downloaded online info, photos included.
  Future<void> clearMetadataCache();
}
