import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/network/api_client.dart';
import 'package:troona/features/metadata/data/models/last_fm_album_dto.dart';
import 'package:troona/features/metadata/data/models/last_fm_artist_dto.dart';
import 'package:troona/features/metadata/data/repositories/metadata_repository_impl.dart';
import 'package:troona/features/metadata/data/sources/last_fm_remote_data_source.dart';
import 'package:troona/features/metadata/data/sources/metadata_cache_data_source.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/domain/repositories/settings_repository.dart';

const _songs = ['One More Time'];
const hash = '638e69b9caaf9f9f3f8826febea7b543';

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
      artist: LastFmArtistData(
        bio: LastFmBioDto(content: 'A bio'),
        similar: [
          LastFmSimilarArtistDto(
            name: 'Justice',
            imageUrl: 'https://lastfm.test/justice.jpg',
          ),
        ],
      ),
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

  /// Thrown by the next Deezer artist lookup only: a dropped connection.
  Object? deezerFailure;

  @override
  Future<String?> fetchDeezerArtistImage(
    String artistName, {
    List<String> songTitles = const [],
  }) async {
    calls.add('deezer:artist');
    final failure = deezerFailure;
    deezerFailure = null;
    if (failure != null) throw failure;
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

/// Serves [chunks], then fails if [cut] is set: a dropped connection.
/// [midway] runs between chunks, while the transfer is still open.
class _Adapter implements HttpClientAdapter {
  final List<List<int>> chunks;
  final bool cut;
  final Future<void> Function()? midway;
  _Adapter(this.chunks, {this.cut = false, this.midway});

  /// Requests served so far.
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    final controller = StreamController<Uint8List>();
    () async {
      for (final c in chunks) {
        controller.add(Uint8List.fromList(c));
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await midway?.call();
      }
      if (cut) controller.addError(const SocketException('connection reset'));
      await controller.close();
    }();
    return ResponseBody(controller.stream, 200);
  }

  @override
  void close({bool force = false}) {}
}

/// Answers [body] to the first request, then the connection drops.
class _FlakyAdapter implements HttpClientAdapter {
  final String body;
  int requests = 0;
  _FlakyAdapter(this.body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (++requests > 1) throw const SocketException('connection reset');
    return ResponseBody.fromString(body, 200);
  }

  @override
  void close({bool force = false}) {}
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
    expect(await repo.getArtistInfo('Daft Punk', songTitles: _songs), isNull);
    expect(await repo.getAlbumInfo('Daft Punk', 'Discovery'), isNull);
    expect(
      await repo.prefetchArtistPhoto(
        artistId: '1',
        artistName: 'Daft Punk',
        songTitles: _songs,
      ),
      isNull,
    );
    expect(remote.calls, isEmpty);
  });

  test('unreadable settings count as off', () async {
    settings.value = null;
    expect(await repo.getArtistInfo('Daft Punk', songTitles: _songs), isNull);
    expect(remote.calls, isEmpty);
  });

  test('info only: Last.fm text, no picture, Deezer untouched', () async {
    settings.value = switches(info: true, photos: false);

    final artist = await repo.getArtistInfo('Daft Punk', songTitles: _songs);
    final album = await repo.getAlbumInfo('Daft Punk', 'Discovery');

    expect(artist?.bio, 'A bio');
    expect(artist?.imageUrl, isNull);
    expect(artist?.similarArtists.single.imageUrl, isNull);
    expect(album?.name, 'An album');
    expect(album?.imageUrl, isNull);
    expect(remote.calls, ['lastfm:artist', 'lastfm:album']);
  });

  test('info only: no photo prefetch and no download', () async {
    settings.value = switches(info: true, photos: false);

    expect(
      await repo.prefetchArtistPhoto(
        artistId: '1',
        artistName: 'Daft Punk',
        songTitles: _songs,
      ),
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

    final artist = await repo.getArtistInfo('Daft Punk', songTitles: _songs);
    final album = await repo.getAlbumInfo('Daft Punk', 'Discovery');

    expect(artist?.bio, isNull);
    expect(artist?.imageUrl, 'https://deezer.test/artist.jpg');
    expect(album?.imageUrl, 'https://deezer.test/album.jpg');
    expect(remote.calls, ['deezer:artist', 'deezer:album']);
  });

  test('both on: text and picture, then served from the cache', () async {
    settings.value = switches(info: true, photos: true);

    final first = await repo.getArtistInfo('Daft Punk', songTitles: _songs);
    expect(first?.bio, 'A bio');
    expect(first?.imageUrl, 'https://deezer.test/artist.jpg');

    remote.calls.clear();
    final second = await repo.getArtistInfo('Daft Punk', songTitles: _songs);
    expect(second, first);
    expect(remote.calls, isEmpty);
  });

  group('photo download', () {
    MetadataRepositoryImpl withAdapter(_Adapter adapter) {
      settings.value = switches(info: false, photos: true);
      return MetadataRepositoryImpl(
        cache: cache,
        remote: remote,
        settingsRepo: settings,
        client: ApiClient(customDio: Dio()..httpClientAdapter = adapter),
        artworkCacheDir: Directory('${tempDir.path}/photos'),
      );
    }

    List<String> leftovers() => Directory(
      '${tempDir.path}/photos/artists',
    ).listSync().map((e) => e.path.split('/').last).toList();

    test('lands complete under its final name', () async {
      final repo = withAdapter(
        _Adapter([
          [1, 2],
          [3, 4],
        ]),
      );
      final path = await repo.downloadAndCacheArtistArtwork(
        artistId: '1',
        imageUrl: 'https://deezer.test/artist.jpg',
      );
      expect(path, isNotNull);
      expect(await File(path!).readAsBytes(), [1, 2, 3, 4]);
      expect(leftovers(), ['1.jpg']);
    });

    // If the app is killed mid-transfer, whatever sits under the final name
    // would pass the "already cached" check on the next launch.
    test('nothing appears under the final name before it completes', () async {
      final seenMidway = <bool>[];
      final target = File('${tempDir.path}/photos/artists/1.jpg');
      final repo = withAdapter(
        _Adapter([
          [1, 2],
          [3, 4],
        ], midway: () async => seenMidway.add(await target.exists())),
      );
      await repo.downloadAndCacheArtistArtwork(
        artistId: '1',
        imageUrl: 'https://deezer.test/artist.jpg',
      );
      expect(seenMidway, [false, false]);
      expect(await target.readAsBytes(), [1, 2, 3, 4]);
    });

    test('a cut connection leaves nothing behind', () async {
      final repo = withAdapter(
        _Adapter([
          [1, 2],
        ], cut: true),
      );
      final path = await repo.downloadAndCacheArtistArtwork(
        artistId: '1',
        imageUrl: 'https://deezer.test/artist.jpg',
      );
      expect(path, isNull);
      expect(leftovers(), isEmpty);
      expect(repo.getCachedArtistArtworkPath('1'), isNull);
    });
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

  test('photos only: one Deezer search per artist per session', () async {
    settings.value = switches(info: false, photos: true);
    await repo.getArtistInfo('Daft Punk', songTitles: _songs);
    await repo.getArtistInfo('Daft Punk', songTitles: _songs);
    expect(remote.calls, ['deezer:artist']);
  });

  test('an unreachable Deezer is asked again on the next visit', () async {
    settings.value = switches(info: false, photos: true);
    remote.deezerFailure = DioException.connectionError(
      requestOptions: RequestOptions(),
      reason: 'offline',
    );

    expect(await repo.getArtistInfo('Daft Punk', songTitles: _songs), isNull);
    final online = await repo.getArtistInfo('Daft Punk', songTitles: _songs);

    expect(online?.imageUrl, 'https://deezer.test/artist.jpg');
    expect(remote.calls, ['deezer:artist', 'deezer:artist']);
  });

  test('photos on but no song to confirm with: Deezer untouched', () async {
    settings.value = switches(info: false, photos: true);
    expect(await repo.getArtistInfo('Daft Punk'), isNull);
    expect(remote.calls, isEmpty);
  });

  group('Deezer remote', () {
    LastFmRemoteDataSourceImpl remoteWith(HttpClientAdapter adapter) =>
        LastFmRemoteDataSourceImpl(
          client: ApiClient(customDio: Dio()..httpClientAdapter = adapter),
        );

    test('throws when Deezer cannot be reached', () async {
      final remote = remoteWith(_Adapter(const [], cut: true));
      await expectLater(
        remote.fetchDeezerArtistImage('Daft Punk', songTitles: _songs),
        throwsA(isA<DioException>()),
      );
    });

    String songs(List<(String, String)> found) => jsonEncode({
      'data': [
        for (final (title, artist) in found)
          {
            'title': title,
            'artist': {
              'name': artist,
              'picture_xl':
                  'https://cdn-images.dzcdn.net/images/artist/$hash/1000x1000.jpg',
            },
          },
      ],
    });

    test('takes the photo of the artist one of their songs confirms', () async {
      final adapter = _Adapter([
        songs([('One More Time', 'Daft Punk')]).codeUnits,
      ]);
      expect(
        await remoteWith(
          adapter,
        ).fetchDeezerArtistImage('Daft Punk', songTitles: _songs),
        contains(hash),
      );
      expect(adapter.requests, 1);
    });

    test('a namesake is never taken, after three songs at most', () async {
      final adapter = _Adapter([
        songs([('Not Theirs', 'Daft Punk')]).codeUnits,
      ]);
      expect(
        await remoteWith(adapter).fetchDeezerArtistImage(
          'Daft Punk',
          songTitles: const ['A', 'B', 'C', 'D'],
        ),
        isNull,
      );
      expect(adapter.requests, 3);
    });

    test('Deezer lost on the second song: not taken for a miss', () async {
      final adapter = _FlakyAdapter(songs([('Not Theirs', 'Daft Punk')]));
      await expectLater(
        remoteWith(
          adapter,
        ).fetchDeezerArtistImage('Daft Punk', songTitles: const ['A', 'B']),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests, 2);
    });

    test('over quota: not taken for a miss', () async {
      final adapter = _Adapter([
        '{"error":{"type":"Exception","message":"Quota limit exceeded","code":4}}'
            .codeUnits,
      ]);
      await expectLater(
        remoteWith(
          adapter,
        ).fetchDeezerArtistImage('Daft Punk', songTitles: _songs),
        throwsA(isA<DioException>()),
      );
    });

    test('no song, no search', () async {
      final adapter = _Adapter(const []);
      expect(
        await remoteWith(adapter).fetchDeezerArtistImage('Daft Punk'),
        isNull,
      );
      expect(adapter.requests, 0);
    });

    test('answers null when Deezer has no match', () async {
      final remote = remoteWith(_Adapter(['{"data":[]}'.codeUnits]));
      expect(
        await remote.fetchDeezerArtistImage('Daft Punk', songTitles: _songs),
        isNull,
      );
    });
  });

  test('concurrent lookups for one artist share one search', () async {
    settings.value = switches(info: false, photos: true);
    await Future.wait([
      repo.getArtistInfo('Daft Punk', songTitles: _songs),
      repo.getArtistInfo('Daft Punk', songTitles: _songs),
    ]);
    expect(remote.calls, ['deezer:artist']);
  });

  test('a photo landing after the delete stays hidden', () async {
    settings.value = switches(info: false, photos: false);
    await repo.forgetPhotos();
    // A download that passed its switch check renames late.
    final late = File('${tempDir.path}/photos/artists/1.jpg');
    await late.create(recursive: true);
    await late.writeAsBytes([1, 2, 3]);

    expect(repo.getCachedArtistArtworkPath('1'), isNull);

    settings.value = switches(info: false, photos: true);
    await repo.getArtistInfo('Daft Punk', songTitles: _songs);
    expect(repo.getCachedArtistArtworkPath('1'), late.path);
  });

  test('forgetting photos keeps bios and tells every artist card', () async {
    settings.value = switches(info: true, photos: true);
    await repo.getArtistInfo('Daft Punk', songTitles: _songs);
    final photo = File('${tempDir.path}/photos/artists/1.jpg');
    await photo.create(recursive: true);
    await photo.writeAsBytes([1]);
    final updates = <String>[];
    final sub = repo.onArtistArtworkUpdated.listen(updates.add);

    await repo.forgetPhotos();
    await pumpEventQueue();
    await sub.cancel();

    expect(await photo.exists(), isFalse);
    expect(updates, [MetadataRepository.allArtists]);
    remote.calls.clear();
    expect(
      (await repo.getArtistInfo('Daft Punk', songTitles: _songs))?.bio,
      'A bio',
    );
    expect(remote.calls, isNot(contains('lastfm:artist')));
  });

  test(
    'a download finishing after photos were turned off is dropped',
    () async {
      late MetadataRepositoryImpl repo;
      repo = MetadataRepositoryImpl(
        cache: cache,
        remote: remote,
        settingsRepo: settings,
        client: ApiClient(
          customDio: Dio()
            ..httpClientAdapter = _Adapter(
              [
                [1, 2],
              ],
              midway: () async =>
                  settings.value = switches(info: false, photos: false),
            ),
        ),
        artworkCacheDir: Directory('${tempDir.path}/photos'),
      );
      settings.value = switches(info: false, photos: true);

      final path = await repo.downloadAndCacheArtistArtwork(
        artistId: '1',
        imageUrl: 'https://deezer.test/artist.jpg',
      );

      expect(path, isNull);
      expect(repo.getCachedArtistArtworkPath('1'), isNull);
    },
  );

  test('unfinished downloads are removed at boot', () async {
    final part = File('${tempDir.path}/photos/artists/1.jpg.123.part');
    final done = File('${tempDir.path}/photos/artists/2.jpg');
    await part.create(recursive: true);
    await done.create(recursive: true);

    await MetadataRepositoryImpl.removeUnfinishedDownloads(
      Directory('${tempDir.path}/photos'),
    );

    expect(await part.exists(), isFalse);
    expect(await done.exists(), isTrue);
  });

  test('names in other scripts have entries of their own', () async {
    await cache.saveArtist(
      '\u041a\u0438\u043d\u043e',
      const LastFmArtistDto(
        artist: LastFmArtistData(
          customImageUrl: 'https://deezer.test/kino.jpg',
        ),
      ),
    );
    expect(await cache.getArtist('\u0421\u043f\u043b\u0438\u043d'), isNull);
    expect(
      (await cache.getArtist(
        '\u041a\u0438\u043d\u043e',
      ))?.artist?.customImageUrl,
      'https://deezer.test/kino.jpg',
    );
    expect(
      MetadataCacheDataSourceImpl.keyOf('Daft Punk'),
      MetadataCacheDataSourceImpl.keyOf(' daft punk '),
    );
  });

  group('photos downloaded before the check', () {
    late Directory photos;
    late Directory jsonCache;

    setUp(() async {
      photos = Directory('${tempDir.path}/photos');
      jsonCache = Directory('${tempDir.path}/json');
      for (final f in [
        '${photos.path}/artists/1.jpg',
        '${photos.path}/albums/album_1.jpg',
        '${jsonCache.path}/artists/daft_punk.json',
        '${jsonCache.path}/albums/daft_punk_discovery.json',
      ]) {
        await File(f).create(recursive: true);
      }
    });

    Future<void> forget(SharedPreferences prefs) =>
        MetadataRepositoryImpl.forgetUncheckedArtistPhotos(
          photos: photos,
          cache: jsonCache,
          prefs: prefs,
        );

    test('go once: artist photos and online info, album covers kept', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await forget(prefs);

      expect(Directory('${photos.path}/artists').existsSync(), isFalse);
      expect(Directory('${jsonCache.path}/artists').existsSync(), isFalse);
      expect(File('${photos.path}/albums/album_1.jpg').existsSync(), isTrue);
      // Named the old way, never read again.
      expect(Directory('${jsonCache.path}/albums').existsSync(), isFalse);
      expect(prefs.getBool(MetadataRepositoryImpl.photosCheckedKey), isTrue);

      // A photo downloaded through the check stays on the next launch.
      await File('${photos.path}/artists/1.jpg').create(recursive: true);
      await forget(prefs);
      expect(File('${photos.path}/artists/1.jpg').existsSync(), isTrue);
    });

    test('marked done with nothing to remove', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await photos.delete(recursive: true);
      await jsonCache.delete(recursive: true);
      await forget(prefs);
      expect(prefs.getBool(MetadataRepositoryImpl.photosCheckedKey), isTrue);
    });
  });
}
