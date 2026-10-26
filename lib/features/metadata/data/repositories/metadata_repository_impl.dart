import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:troona/core/network/api_client.dart';
import 'package:troona/core/utils/app_logger.dart';
import 'package:troona/features/metadata/data/models/last_fm_album_dto.dart';
import 'package:troona/features/metadata/data/models/last_fm_artist_dto.dart';
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

  /// Deezer answers for this session, misses included: without bios there is
  /// no cache entry to keep them, and each page visit searched again. A
  /// lookup in flight is shared; one that could not reach Deezer is dropped
  /// so the next visit asks again.
  final _deezerLookups = <String, Future<String?>>{};

  MetadataRepositoryImpl({
    required MetadataCacheDataSource cache,
    required LastFmRemoteDataSource remote,
    required SettingsRepository settingsRepo,
    required ApiClient client,
    required Directory artworkCacheDir,
  }) : _cache = cache,
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

  Future<String?> _deezer(String key, Future<String?> Function() fetch) =>
      _deezerLookups[key] ??= fetch().catchError((Object e) {
        _deezerLookups.remove(key);
        appLogger.d('Deezer unreachable, will ask again later: $e');
        return null;
      });

  /// The two opt-in switches. Unreadable settings count as both off: the
  /// app stays offline unless the user said otherwise.
  Future<({bool info, bool photos})> _onlineSwitches() async {
    final settings = (await _settingsRepo.loadSettings()).fold(
      (_) => null,
      (s) => s,
    );
    return (
      info: settings?.fetchOnlineMetadata ?? false,
      photos: settings?.fetchArtistArtwork ?? false,
    );
  }

  // Bios and stats come from Last.fm (info switch); pictures fall back to
  // Deezer (photos switch). Each source is only contacted when its switch
  // is on.
  @override
  Future<ArtistOnlineInfo?> getArtistInfo(
    String artistName, {
    bool forceRefresh = false,
  }) async {
    try {
      final online = await _onlineSwitches();
      if (!online.info && !online.photos) return null;

      LastFmArtistDto? dto;
      if (online.info) {
        dto = forceRefresh ? null : await _cache.getArtist(artistName);
        if (dto == null) {
          dto = await _remote.getArtistInfo(artistName: artistName);
          if (dto != null) await _cache.saveArtist(artistName, dto);
        }
      }
      if (!online.photos) return dto?.toDomain(withImage: false);
      if (dto?.artist?.bestImageUrl != null) return dto!.toDomain();

      final deezerImg = await _deezer(
        'artist:$artistName',
        () => _remote.fetchDeezerArtistImage(artistName),
      );
      if (deezerImg == null || deezerImg.isEmpty) return dto?.toDomain();
      final artist = dto?.artist;
      if (artist == null) return ArtistOnlineInfo(imageUrl: deezerImg);
      final updated = dto!.copyWith(
        artist: artist.copyWith(customImageUrl: deezerImg),
      );
      await _cache.saveArtist(artistName, updated);
      return updated.toDomain();
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
      final online = await _onlineSwitches();
      if (!online.info && !online.photos) return null;

      LastFmAlbumDto? dto;
      if (online.info) {
        dto = forceRefresh
            ? null
            : await _cache.getAlbum(artistName, albumName);
        if (dto == null) {
          dto = await _remote.getAlbumInfo(
            artistName: artistName,
            albumName: albumName,
          );
          if (dto != null) await _cache.saveAlbum(artistName, albumName, dto);
        }
      }
      if (!online.photos) return dto?.toDomain(withImage: false);
      if (dto?.album?.bestImageUrl != null) return dto!.toDomain();

      final deezerCover = await _deezer(
        'album:$artistName\u0000$albumName',
        () => _remote.fetchDeezerAlbumCover(artistName, albumName),
      );
      if (deezerCover == null || deezerCover.isEmpty) return dto?.toDomain();
      final album = dto?.album;
      if (album == null) return AlbumOnlineInfo(imageUrl: deezerCover);
      final updated = dto!.copyWith(
        album: album.copyWith(customImageUrl: deezerCover),
      );
      await _cache.saveAlbum(artistName, albumName, updated);
      return updated.toDomain();
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
      if (!(await _onlineSwitches()).photos) return null;

      if (imageUrl.isEmpty) return null;

      final artistDir = Directory('${_artworkCacheDir.path}/artists');
      await artistDir.create(recursive: true);

      final safeId = artistId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final targetFile = File('${artistDir.path}/$safeId.jpg');

      if (await targetFile.exists() && (await targetFile.length()) > 0) {
        return targetFile.path;
      }

      if (await _download(imageUrl, targetFile)) {
        appLogger.d('Downloaded artist artwork: ${targetFile.path}');
        _artistArtworkUpdatedController.add(artistId);
        return targetFile.path;
      }
      return null;
    } catch (e) {
      appLogger.w(
        'MetadataRepositoryImpl.downloadAndCacheArtistArtwork failed: $e',
      );
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
    if (!(await _onlineSwitches()).photos) return null;

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
      if (!(await _onlineSwitches()).photos) return null;

      if (imageUrl.isEmpty) return null;

      final albumDir = Directory('${_artworkCacheDir.path}/albums');
      await albumDir.create(recursive: true);

      final safeId = albumId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final targetFile = File('${albumDir.path}/album_$safeId.jpg');

      if (await targetFile.exists() && (await targetFile.length()) > 0) {
        return targetFile.path;
      }

      if (await _download(imageUrl, targetFile)) {
        appLogger.d('Downloaded album artwork: ${targetFile.path}');
        return targetFile.path;
      }
      return null;
    } catch (e) {
      appLogger.w(
        'MetadataRepositoryImpl.downloadAndCacheAlbumArtwork failed: $e',
      );
      return null;
    }
  }

  /// Downloads into a side file, then renames it into place: a cut
  /// connection never leaves a truncated picture behind that the next
  /// "already cached" check would accept.
  Future<bool> _download(String url, File target) async {
    final part = File(
      '${target.path}.${DateTime.now().microsecondsSinceEpoch}.part',
    );
    try {
      await _client.dio.download(
        url,
        part.path,
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );
      if (await part.length() == 0) return false;
      // The switch may have been turned off while this was downloading.
      if (!(await _onlineSwitches()).photos) return false;
      await part.rename(target.path);
      return true;
    } finally {
      if (await part.exists()) await part.delete();
    }
  }

  @override
  Future<int> getMetadataCacheSizeBytes() async {
    return _cache.getCacheSizeBytes();
  }

  @override
  Future<void> clearMetadataCache() async {
    // Also removes the downloaded photos: they live inside that cache.
    await _cache.clearCache();
    _deezerLookups.clear();
    _artistArtworkUpdatedController.add(MetadataRepository.allArtists);
  }

  @override
  Future<void> forgetPhotos() async {
    try {
      if (await _artworkCacheDir.exists()) {
        await _artworkCacheDir.delete(recursive: true);
      }
    } catch (e) {
      appLogger.w('MetadataRepositoryImpl.forgetPhotos failed: $e');
    }
    _deezerLookups.clear();
    _artistArtworkUpdatedController.add(MetadataRepository.allArtists);
  }

  /// Removes `.part` files an app kill left mid-download.
  static Future<void> removeUnfinishedDownloads(Directory photos) async {
    try {
      if (!await photos.exists()) return;
      await for (final f in photos.list(recursive: true)) {
        if (f is File && f.path.endsWith('.part')) await f.delete();
      }
    } catch (_) {}
  }
}
