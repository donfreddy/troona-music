import 'dart:convert';
import 'dart:io';

import 'package:troona/core/network/api_client.dart';
import 'package:troona/core/network/api_endpoints.dart';
import 'package:troona/core/utils/app_logger.dart';
import 'package:troona/features/metadata/data/models/last_fm_album_dto.dart';
import 'package:troona/features/metadata/data/models/last_fm_artist_dto.dart';

abstract interface class LastFmRemoteDataSource {
  Future<LastFmArtistDto?> getArtistInfo({
    required String artistName,
    String? language,
  });

  Future<LastFmAlbumDto?> getAlbumInfo({
    required String artistName,
    required String albumName,
    String? language,
  });

  Future<String?> fetchDeezerArtistImage(String artistName);
  Future<String?> fetchDeezerAlbumCover(String artistName, String albumName);
}

class LastFmRemoteDataSourceImpl implements LastFmRemoteDataSource {
  final ApiClient _client;

  LastFmRemoteDataSourceImpl({required ApiClient client}) : _client = client;

  String _resolveLanguage(String? language) {
    if (language != null && language.isNotEmpty) return language;
    try {
      final locale = Platform.localeName.split('_').first.toLowerCase();
      return locale.isNotEmpty ? locale : 'en';
    } catch (_) {
      return 'en';
    }
  }

  @override
  Future<LastFmArtistDto?> getArtistInfo({
    required String artistName,
    String? language,
  }) async {
    if (LastFmArtistData.isUnknownName(artistName)) return null;
    try {
      final lang = _resolveLanguage(language);
      final response = await _client.get(
        '',
        queryParameters: {
          'method': ApiEndpoints.methodArtistGetInfo,
          'artist': artistName,
          'api_key': ApiEndpoints.lastFmApiKey,
          'format': 'json',
          'autocorrect': '1',
          'lang': lang,
        },
      );

      var data = response.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }

      LastFmArtistDto? dto;
      if (data is Map && !data.containsKey('error')) {
        dto = LastFmArtistDto.fromJson(Map<String, dynamic>.from(data));
      }

      return dto;
    } catch (e) {
      appLogger.w('LastFmRemoteDataSource.getArtistInfo failed silently: $e');
      return null;
    }
  }

  @override
  Future<LastFmAlbumDto?> getAlbumInfo({
    required String artistName,
    required String albumName,
    String? language,
  }) async {
    if (LastFmArtistData.isUnknownName(artistName)) return null;
    try {
      final lang = _resolveLanguage(language);
      final response = await _client.get(
        '',
        queryParameters: {
          'method': ApiEndpoints.methodAlbumGetInfo,
          'artist': artistName,
          'album': albumName,
          'api_key': ApiEndpoints.lastFmApiKey,
          'format': 'json',
          'autocorrect': '1',
          'lang': lang,
        },
      );

      var data = response.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }

      LastFmAlbumDto? dto;
      if (data is Map && !data.containsKey('error')) {
        dto = LastFmAlbumDto.fromJson(Map<String, dynamic>.from(data));
      }

      return dto;
    } catch (e) {
      appLogger.w('LastFmRemoteDataSource.getAlbumInfo failed silently: $e');
      return null;
    }
  }

  @override
  Future<String?> fetchDeezerArtistImage(String artistName) async {
    if (LastFmArtistData.isUnknownName(artistName)) return null;
    try {
      final response = await _client.dio.get(
        'https://api.deezer.com/search/artist',
        queryParameters: {'q': artistName.trim(), 'limit': 1},
      );
      var data = response.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }
      if (data is Map && data['data'] is List) {
        final list = data['data'] as List;
        if (list.isNotEmpty && list.first is Map) {
          final first = list.first as Map;
          final xl = first['picture_xl'] as String?;
          final big = first['picture_big'] as String?;
          final med = first['picture_medium'] as String?;
          return xl ?? big ?? med;
        }
      }
    } catch (e) {
      appLogger.d('Deezer artist image lookup failed silently: $e');
    }
    return null;
  }

  @override
  Future<String?> fetchDeezerAlbumCover(
    String artistName,
    String albumName,
  ) async {
    if (LastFmArtistData.isUnknownName(artistName)) return null;
    try {
      final response = await _client.dio.get(
        'https://api.deezer.com/search/album',
        queryParameters: {
          'q': '${artistName.trim()} ${albumName.trim()}',
          'limit': 1,
        },
      );
      var data = response.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }
      if (data is Map && data['data'] is List) {
        final list = data['data'] as List;
        if (list.isNotEmpty && list.first is Map) {
          final first = list.first as Map;
          final xl = first['cover_xl'] as String?;
          final big = first['cover_big'] as String?;
          final med = first['cover_medium'] as String?;
          return xl ?? big ?? med;
        }
      }
    } catch (e) {
      appLogger.d('Deezer album cover lookup failed silently: $e');
    }
    return null;
  }
}
