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
}

class LastFmRemoteDataSourceImpl implements LastFmRemoteDataSource {
  final ApiClient _client;

  LastFmRemoteDataSourceImpl({required ApiClient client}) : _client = client;

  String _resolveLanguage(String? language) {
    if (language != null && language.isNotEmpty) return language;
    try {
      final locale = Platform.localeName.split('_').first.toLowerCase();
      return locale.isNotEmpty ? locale : 'fr';
    } catch (_) {
      return 'fr';
    }
  }

  @override
  Future<LastFmArtistDto?> getArtistInfo({
    required String artistName,
    String? language,
  }) async {
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

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('error')) {
          appLogger.d('Last.fm artist not found or error: ${data['message']}');
          return null;
        }
        return LastFmArtistDto.fromJson(data);
      }
      return null;
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

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('error')) {
          appLogger.d('Last.fm album not found or error: ${data['message']}');
          return null;
        }
        return LastFmAlbumDto.fromJson(data);
      }
      return null;
    } catch (e) {
      appLogger.w('LastFmRemoteDataSource.getAlbumInfo failed silently: $e');
      return null;
    }
  }
}
