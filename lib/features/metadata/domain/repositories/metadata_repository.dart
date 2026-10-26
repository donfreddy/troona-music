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
    required int albumId,
    required String imageUrl,
  });

  Future<int> getMetadataCacheSizeBytes();
  Future<void> clearMetadataCache();
}
