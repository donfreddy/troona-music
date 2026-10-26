import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/metadata/domain/entities/album_online_info.dart';
import 'package:troona/features/metadata/domain/entities/artist_online_info.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:troona/features/metadata/presentation/cubit/album_metadata_cubit.dart';
import 'package:troona/features/metadata/presentation/cubit/artist_metadata_cubit.dart';

/// Answers with a picture while [photos] is on, text only once it is off.
class _Repo implements MetadataRepository {
  bool photos = true;
  final updates = StreamController<String>.broadcast();

  /// When set, the next artist lookup waits for it: a slow network.
  Completer<void>? gate;

  void turnPhotosOff() {
    photos = false;
    updates.add(MetadataRepository.allArtists);
  }

  @override
  Future<ArtistOnlineInfo?> getArtistInfo(
    String artistName, {
    bool forceRefresh = false,
  }) async {
    final wasOn = photos;
    final wait = gate;
    gate = null;
    await wait?.future;
    return ArtistOnlineInfo(
      bio: 'A bio',
      imageUrl: wasOn ? 'https://deezer.test/artist.jpg' : null,
      similarArtists: [
        SimilarArtistInfo(
          name: 'Justice',
          imageUrl: wasOn ? 'https://lastfm.test/justice.jpg' : null,
        ),
      ],
    );
  }

  @override
  Future<AlbumOnlineInfo?> getAlbumInfo(
    String artistName,
    String albumName, {
    bool forceRefresh = false,
  }) async => AlbumOnlineInfo(
    wiki: 'A wiki',
    imageUrl: photos ? 'https://deezer.test/album.jpg' : null,
  );

  @override
  Future<String?> downloadAndCacheArtistArtwork({
    required String artistId,
    required String imageUrl,
  }) async => '/photos/artists/$artistId.jpg';

  @override
  Future<String?> downloadAndCacheAlbumArtwork({
    required String albumId,
    required String imageUrl,
  }) async => '/photos/albums/$albumId.jpg';

  @override
  Stream<String> get onArtistArtworkUpdated => updates.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const artist = Artist(
    id: 'a1',
    name: 'Daft Punk',
    albumCount: 1,
    trackCount: 1,
  );
  const album = Album(
    id: 'b1',
    name: 'Discovery',
    artist: 'Daft Punk',
    artistId: 1,
    trackCount: 1,
  );

  late _Repo repo;

  setUp(() => repo = _Repo());
  tearDown(() => repo.updates.close());

  group('photos turned off while a page stays open', () {
    test('the artist page drops its online photo and URLs', () async {
      final cubit = ArtistMetadataCubit(repo: repo);
      addTearDown(cubit.close);
      await cubit.loadArtistMetadata(artist);
      expect((cubit.state as ArtistMetadataLoaded).localImagePath, isNotNull);

      repo.turnPhotosOff();
      await pumpEventQueue();

      final state = cubit.state as ArtistMetadataLoaded;
      expect(state.info.bio, 'A bio');
      expect(state.info.imageUrl, isNull);
      expect(state.localImagePath, isNull);
      expect(state.info.similarArtists.single.imageUrl, isNull);
    });

    test('the album page drops its online cover', () async {
      final cubit = AlbumMetadataCubit(repo: repo);
      addTearDown(cubit.close);
      await cubit.loadAlbumMetadata(album);
      expect((cubit.state as AlbumMetadataLoaded).localImagePath, isNotNull);

      repo.turnPhotosOff();
      await pumpEventQueue();

      final state = cubit.state as AlbumMetadataLoaded;
      expect(state.info.wiki, 'A wiki');
      expect(state.info.imageUrl, isNull);
      expect(state.localImagePath, isNull);
    });

    test('a load started before the switch cannot land after it', () async {
      final cubit = ArtistMetadataCubit(repo: repo);
      addTearDown(cubit.close);
      final network = repo.gate = Completer<void>();
      final slow = cubit.loadArtistMetadata(artist);
      await pumpEventQueue();

      repo.turnPhotosOff();
      await pumpEventQueue();
      // The earlier lookup now answers, with the photo it saw while on.
      network.complete();
      await slow;
      await pumpEventQueue();

      expect((cubit.state as ArtistMetadataLoaded).info.imageUrl, isNull);
    });
  });

  test('a page closed mid-load does not throw', () async {
    final cubit = ArtistMetadataCubit(repo: repo);
    final network = repo.gate = Completer<void>();
    final load = cubit.loadArtistMetadata(artist);
    await cubit.close();
    network.complete();
    await expectLater(load, completes);
  });
}
