import 'package:troona/features/metadata/domain/entities/album_online_info.dart';
import 'package:troona/features/metadata/domain/entities/artist_online_info.dart';

abstract interface class MetadataRepository {
  Future<ArtistOnlineInfo?> getArtistInfo(
    String artistName, {
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

  String? getCachedArtistArtworkPath(String artistId);

  /// Emits an artist id when its photo changes, or [allArtists] after photos
  /// were removed in bulk.
  Stream<String> get onArtistArtworkUpdated;

  static const allArtists = '*';

  /// Deletes every downloaded artist photo and album cover, keeping bios.
  /// Called when the photos switch is turned off.
  Future<void> forgetPhotos();

  Future<String?> prefetchArtistPhoto({
    required String artistId,
    required String artistName,
  });

  Future<int> getMetadataCacheSizeBytes();

  /// Deletes all downloaded online info, photos included.
  Future<void> clearMetadataCache();
}
