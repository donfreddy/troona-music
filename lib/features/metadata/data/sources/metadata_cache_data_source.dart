import 'dart:convert';
import 'dart:io';

import 'package:troona/core/utils/app_logger.dart';
import 'package:troona/features/metadata/data/models/last_fm_album_dto.dart';
import 'package:troona/features/metadata/data/models/last_fm_artist_dto.dart';

abstract interface class MetadataCacheDataSource {
  Future<LastFmArtistDto?> getArtist(String artistName);
  Future<void> saveArtist(String artistName, LastFmArtistDto dto);

  Future<LastFmAlbumDto?> getAlbum(String artistName, String albumName);
  Future<void> saveAlbum(
    String artistName,
    String albumName,
    LastFmAlbumDto dto,
  );

  Future<int> getCacheSizeBytes();
  Future<void> clearCache();
}

class MetadataCacheDataSourceImpl implements MetadataCacheDataSource {
  final Directory cacheDir;
  static const Duration defaultTtl = Duration(days: 30);

  MetadataCacheDataSourceImpl({required this.cacheDir});

  Directory get _artistsDir => Directory('${cacheDir.path}/artists');
  Directory get _albumsDir => Directory('${cacheDir.path}/albums');

  Future<void> init() async {
    await _artistsDir.create(recursive: true);
    await _albumsDir.create(recursive: true);
  }

  String _sanitizeKey(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  @override
  Future<LastFmArtistDto?> getArtist(String artistName) async {
    try {
      final key = _sanitizeKey(artistName);
      final file = File('${_artistsDir.path}/$key.json');
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final cachedAt = json['_cached_at'] as int?;

      if (cachedAt != null) {
        final age = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(cachedAt),
        );
        if (age > defaultTtl) {
          await file.delete();
          return null;
        }
      }

      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return LastFmArtistDto.fromJson(data);
    } catch (e) {
      appLogger.w('MetadataCacheDataSource.getArtist failed: $e');
      return null;
    }
  }

  @override
  Future<void> saveArtist(String artistName, LastFmArtistDto dto) async {
    try {
      await _artistsDir.create(recursive: true);
      final key = _sanitizeKey(artistName);
      final file = File('${_artistsDir.path}/$key.json');
      final payload = {
        '_cached_at': DateTime.now().millisecondsSinceEpoch,
        'data': dto.toJson(),
      };
      await file.writeAsString(jsonEncode(payload));
    } catch (e) {
      appLogger.w('MetadataCacheDataSource.saveArtist failed: $e');
    }
  }

  @override
  Future<LastFmAlbumDto?> getAlbum(String artistName, String albumName) async {
    try {
      final key = '${_sanitizeKey(artistName)}__${_sanitizeKey(albumName)}';
      final file = File('${_albumsDir.path}/$key.json');
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final cachedAt = json['_cached_at'] as int?;

      if (cachedAt != null) {
        final age = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(cachedAt),
        );
        if (age > defaultTtl) {
          await file.delete();
          return null;
        }
      }

      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return LastFmAlbumDto.fromJson(data);
    } catch (e) {
      appLogger.w('MetadataCacheDataSource.getAlbum failed: $e');
      return null;
    }
  }

  @override
  Future<void> saveAlbum(
    String artistName,
    String albumName,
    LastFmAlbumDto dto,
  ) async {
    try {
      await _albumsDir.create(recursive: true);
      final key = '${_sanitizeKey(artistName)}__${_sanitizeKey(albumName)}';
      final file = File('${_albumsDir.path}/$key.json');
      final payload = {
        '_cached_at': DateTime.now().millisecondsSinceEpoch,
        'data': dto.toJson(),
      };
      await file.writeAsString(jsonEncode(payload));
    } catch (e) {
      appLogger.w('MetadataCacheDataSource.saveAlbum failed: $e');
    }
  }

  @override
  Future<int> getCacheSizeBytes() async {
    try {
      if (!await cacheDir.exists()) return 0;
      int total = 0;
      await for (final file in cacheDir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (file is File) {
          total += await file.length();
        }
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await init();
      }
    } catch (e) {
      appLogger.w('MetadataCacheDataSource.clearCache failed: $e');
    }
  }
}
