import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/network/api_client.dart';
import 'package:troona/features/metadata/data/models/last_fm_album_dto.dart';
import 'package:troona/features/metadata/data/models/last_fm_artist_dto.dart';
import 'package:troona/features/metadata/data/repositories/metadata_repository_impl.dart';
import 'package:troona/features/metadata/data/sources/last_fm_remote_data_source.dart';
import 'package:troona/features/metadata/data/sources/metadata_cache_data_source.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/domain/repositories/settings_repository.dart';

class _Settings implements SettingsRepository {
  AppSettings? value;
  _Settings(this.value);

  @override
  Future<Either<Failure, AppSettings>> loadSettings() async =>
      value == null ? left(const CacheFailure('unreadable')) : right(value!);

  @override
  Future<Either<Failure, Unit>> saveSettings(AppSettings settings) async =>
      right(unit);

  @override
  Future<Either<Failure, Unit>> resetSettings() async => right(unit);
}

/// Last.fm answers with a bio and no picture; Deezer with a picture.
class _Remote implements LastFmRemoteDataSource {
  final calls = <String>[];

  @override
  Future<LastFmArtistDto?> getArtistInfo({
    required String artistName,
    String? language,
  }) async {
    calls.add('lastfm:artist');
    return const LastFmArtistDto(
      artist: LastFmArtistData(bio: LastFmBioDto(content: 'A bio')),
    );
  }

  @override
  Future<LastFmAlbumDto?> getAlbumInfo({
    required String artistName,
    required String albumName,
    String? language,
  }) async {
    calls.add('lastfm:album');
    return const LastFmAlbumDto(album: LastFmAlbumData(name: 'An album'));
  }

  @override
  Future<String?> fetchDeezerArtistImage(String artistName) async {
    calls.add('deezer:artist');
    return 'https://deezer.test/artist.jpg';
  }

  @override
  Future<String?> fetchDeezerAlbumCover(
    String artistName,
    String albumName,
  ) async {
    calls.add('deezer:album');
    return 'https://deezer.test/album.jpg';
  }
}

void main() {
  late Directory tempDir;
  late MetadataCacheDataSourceImpl cache;
  late _Remote remote;
  late _Settings settings;
  late MetadataRepositoryImpl repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('metadata_switches_');
    cache = MetadataCacheDataSourceImpl(cacheDir: tempDir);
    await cache.init();
    remote = _Remote();
    settings = _Settings(const AppSettings());
    repo = MetadataRepositoryImpl(
      cache: cache,
      remote: remote,
      settingsRepo: settings,
      client: ApiClient(),
      artworkCacheDir: Directory('${tempDir.path}/photos'),
    );
  });

  tearDown(() => tempDir.delete(recursive: true));

  AppSettings switches({required bool info, required bool photos}) =>
      AppSettings(fetchOnlineMetadata: info, fetchArtistArtwork: photos);

  test('both switches off: no request at all', () async {
    expect(await repo.getArtistInfo('Daft Punk'), isNull);
    expect(await repo.getAlbumInfo('Daft Punk', 'Discovery'), isNull);
    expect(
      await repo.prefetchArtistPhoto(artistId: '1', artistName: 'Daft Punk'),
      isNull,
    );
    expect(remote.calls, isEmpty);
  });

  test('unreadable settings count as off', () async {
    settings.value = null;
    expect(await repo.getArtistInfo('Daft Punk'), isNull);
    expect(remote.calls, isEmpty);
  });

  test('info only: Last.fm text, no picture, Deezer untouched', () async {
    settings.value = switches(info: true, photos: false);

    final artist = await repo.getArtistInfo('Daft Punk');
    final album = await repo.getAlbumInfo('Daft Punk', 'Discovery');

    expect(artist?.bio, 'A bio');
    expect(artist?.imageUrl, isNull);
    expect(album?.name, 'An album');
    expect(album?.imageUrl, isNull);
    expect(remote.calls, ['lastfm:artist', 'lastfm:album']);
  });

  test('info only: no photo prefetch and no download', () async {
    settings.value = switches(info: true, photos: false);

    expect(
      await repo.prefetchArtistPhoto(artistId: '1', artistName: 'Daft Punk'),
      isNull,
    );
    expect(
      await repo.downloadAndCacheArtistArtwork(
        artistId: '1',
        imageUrl: 'https://deezer.test/artist.jpg',
      ),
      isNull,
    );
    expect(remote.calls, isEmpty);
  });

  test('photos only: Deezer picture, Last.fm untouched', () async {
    settings.value = switches(info: false, photos: true);

    final artist = await repo.getArtistInfo('Daft Punk');
    final album = await repo.getAlbumInfo('Daft Punk', 'Discovery');

    expect(artist?.bio, isNull);
    expect(artist?.imageUrl, 'https://deezer.test/artist.jpg');
    expect(album?.imageUrl, 'https://deezer.test/album.jpg');
    expect(remote.calls, ['deezer:artist', 'deezer:album']);
  });

  test('both on: text and picture, then served from the cache', () async {
    settings.value = switches(info: true, photos: true);

    final first = await repo.getArtistInfo('Daft Punk');
    expect(first?.bio, 'A bio');
    expect(first?.imageUrl, 'https://deezer.test/artist.jpg');

    remote.calls.clear();
    final second = await repo.getArtistInfo('Daft Punk');
    expect(second, first);
    expect(remote.calls, isEmpty);
  });

  test('clearing online info removes downloaded photos too', () async {
    final photo = File('${tempDir.path}/photos/artists/1.jpg');
    await photo.create(recursive: true);
    await photo.writeAsBytes([1, 2, 3]);
    expect(repo.getCachedArtistArtworkPath('1'), photo.path);
    expect(await repo.getMetadataCacheSizeBytes(), greaterThan(0));

    await repo.clearMetadataCache();

    expect(await photo.exists(), isFalse);
    expect(repo.getCachedArtistArtworkPath('1'), isNull);
  });
}
