import 'dart:async';
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
  final _artistArtworkUpdatedController = StreamController<String>.broadcast();

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
  Stream<String> get onArtistArtworkUpdated =>
      _artistArtworkUpdatedController.stream;

  @override
  String? getCachedArtistArtworkPath(String artistId) {
    try {
      final safeId = artistId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final targetFile = File('${_artworkCacheDir.path}/artists/$safeId.jpg');
      if (targetFile.existsSync() && targetFile.lengthSync() > 0) {
        return targetFile.path;
      }
    } catch (_) {}
    return null;
  }

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
          if (cached.artist?.bestImageUrl != null) {
            return cached.toDomain();
          }
          final deezerImg = await _remote.fetchDeezerArtistImage(artistName);
          if (deezerImg != null && deezerImg.isNotEmpty) {
            final updated = cached.copyWith(
              artist: cached.artist?.copyWith(customImageUrl: deezerImg),
            );
            await _cache.saveArtist(artistName, updated);
            return updated.toDomain();
          }
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
          if (cached.album?.bestImageUrl != null) {
            return cached.toDomain();
          }
          final deezerCover =
              await _remote.fetchDeezerAlbumCover(artistName, albumName);
          if (deezerCover != null && deezerCover.isNotEmpty) {
            final updated = cached.copyWith(
              album: cached.album?.copyWith(customImageUrl: deezerCover),
            );
            await _cache.saveAlbum(artistName, albumName, updated);
            return updated.toDomain();
          }
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
        _artistArtworkUpdatedController.add(artistId);
        return targetFile.path;
      }
      return null;
    } catch (e) {
      appLogger.w('MetadataRepositoryImpl.downloadAndCacheArtistArtwork failed: $e');
      return null;
    }
  }

  @override
  Future<String?> prefetchArtistPhoto({
    required String artistId,
    required String artistName,
  }) async {
    final cached = getCachedArtistArtworkPath(artistId);
    if (cached != null) return cached;

    final info = await getArtistInfo(artistName);
    if (info == null || info.imageUrl == null || info.imageUrl!.isEmpty) {
      return null;
    }

    return downloadAndCacheArtistArtwork(
      artistId: artistId,
      imageUrl: info.imageUrl!,
    );
  }

  @override
  Future<String?> downloadAndCacheAlbumArtwork({
    required String albumId,
    required String imageUrl,
  }) async {
    try {
      final settingsRes = await _settingsRepo.loadSettings();
      final settings = settingsRes.fold((_) => null, (s) => s);
      if (settings != null && !settings.fetchArtistArtwork) {
        return null;
      }

      if (imageUrl.isEmpty) return null;

      final albumDir = Directory('${_artworkCacheDir.path}/albums');
      await albumDir.create(recursive: true);

      final safeId = albumId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final targetFile = File('${albumDir.path}/album_$safeId.jpg');

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
        appLogger.d('Downloaded album artwork: ${targetFile.path}');
        return targetFile.path;
      }
      return null;
    } catch (e) {
      appLogger.w('MetadataRepositoryImpl.downloadAndCacheAlbumArtwork failed: $e');
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
