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

  Stream<String> get onArtistArtworkUpdated;

  Future<String?> prefetchArtistPhoto({
    required String artistId,
    required String artistName,
  });

  Future<int> getMetadataCacheSizeBytes();
  Future<void> clearMetadataCache();
}
