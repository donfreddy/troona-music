import 'dart:io';

import 'package:dio/dio.dart';
import 'package:troona/core/network/api_client.dart';
import 'package:troona/core/utils/app_logger.dart';
import 'package:troona/features/metadata/data/sources/last_fm_remote_data_source.dart';
import 'package:troona/features/metadata/data/sources/metadata_cache_data_source.dart';
import 'package:troona/features/metadata/domain/entities/album_online_info.dart';
import 'package:troona/features/metadata/domain/entities/artist_online_info.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:troona/features/settings/domain/repositories/settings_repository.dart';

class MetadataRepositoryImpl implements MetadataRepository {
  final MetadataCacheDataSource _cache;
  final LastFmRemoteDataSource _remote;
  final SettingsRepository _settingsRepo;
  final ApiClient _client;
  final Directory _artworkCacheDir;

  MetadataRepositoryImpl({
    required MetadataCacheDataSource cache,
    required LastFmRemoteDataSource remote,
    required SettingsRepository settingsRepo,
    required ApiClient client,
    required Directory artworkCacheDir,
  })  : _cache = cache,
        _remote = remote,
        _settingsRepo = settingsRepo,
        _client = client,
        _artworkCacheDir = artworkCacheDir;

  @override
  Future<ArtistOnlineInfo?> getArtistInfo(
    String artistName, {
    bool forceRefresh = false,
  }) async {
    try {
      final settingsRes = await _settingsRepo.loadSettings();
      final settings = settingsRes.fold((_) => null, (s) => s);
      if (settings != null && !settings.fetchOnlineMetadata) {
        return null;
      }

      if (!forceRefresh) {
        final cached = await _cache.getArtist(artistName);
        if (cached != null) {
          return cached.toDomain();
        }
      }

      final dto = await _remote.getArtistInfo(artistName: artistName);
      if (dto != null) {
        await _cache.saveArtist(artistName, dto);
        return dto.toDomain();
      }
      return null;
    } catch (e) {
      appLogger.w('MetadataRepositoryImpl.getArtistInfo failed silently: $e');
      return null;
    }
  }

  @override
  Future<AlbumOnlineInfo?> getAlbumInfo(
    String artistName,
    String albumName, {
    bool forceRefresh = false,
  }) async {
    try {
      final settingsRes = await _settingsRepo.loadSettings();
      final settings = settingsRes.fold((_) => null, (s) => s);
      if (settings != null && !settings.fetchOnlineMetadata) {
        return null;
      }

      if (!forceRefresh) {
        final cached = await _cache.getAlbum(artistName, albumName);
        if (cached != null) {
          return cached.toDomain();
        }
      }

      final dto = await _remote.getAlbumInfo(
        artistName: artistName,
        albumName: albumName,
      );
      if (dto != null) {
        await _cache.saveAlbum(artistName, albumName, dto);
        return dto.toDomain();
      }
      return null;
    } catch (e) {
      appLogger.w('MetadataRepositoryImpl.getAlbumInfo failed silently: $e');
      return null;
    }
  }

  @override
  Future<String?> downloadAndCacheArtistArtwork({
    required String artistId,
    required String imageUrl,
  }) async {
    try {
      final settingsRes = await _settingsRepo.loadSettings();
      final settings = settingsRes.fold((_) => null, (s) => s);
      if (settings != null && !settings.fetchArtistArtwork) {
        return null;
      }

      if (imageUrl.isEmpty) return null;

      final artistDir = Directory('${_artworkCacheDir.path}/artists');
      await artistDir.create(recursive: true);

      final safeId = artistId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final targetFile = File('${artistDir.path}/$safeId.jpg');

      if (await targetFile.exists() && (await targetFile.length()) > 0) {
        return targetFile.path;
      }

      await _client.dio.download(
        imageUrl,
        targetFile.path,
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (await targetFile.exists() && (await targetFile.length()) > 0) {
        appLogger.d('Downloaded artist artwork: ${targetFile.path}');
        return targetFile.path;
      }
      return null;
    } catch (e) {
      appLogger.w('MetadataRepositoryImpl.downloadAndCacheArtistArtwork failed: $e');
      return null;
    }
  }

  @override
  Future<int> getMetadataCacheSizeBytes() async {
    return _cache.getCacheSizeBytes();
  }

  @override
  Future<void> clearMetadataCache() async {
    await _cache.clearCache();
  }
}
