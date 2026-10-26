import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/metadata/data/models/last_fm_album_dto.dart';
import 'package:troona/features/metadata/data/models/last_fm_artist_dto.dart';
import 'package:troona/features/metadata/data/sources/metadata_cache_data_source.dart';

void main() {
  group('LastFm DTO Parsing & HTML Cleaning', () {
    test('cleans HTML anchor tags and Last.fm boilerplate from artist bio', () {
      final json = {
        'artist': {
          'name': 'Daft Punk',
          'stats': {
            'listeners': '4500000',
            'playcount': '180000000',
          },
          'bio': {
            'published': '2023-01-01',
            'content':
                'Daft Punk was a French electronic music duo. <a href="https://www.last.fm/music/Daft+Punk">Read more on Last.fm</a>. User-contributed text is available under Creative Commons.',
          },
          'image': [
            {'#text': 'https://lastfm.freetls.fastly.net/small.png', 'size': 'small'},
            {'#text': 'https://lastfm.freetls.fastly.net/mega.png', 'size': 'mega'},
          ],
        },
      };

      final dto = LastFmArtistDto.fromJson(json);
      final domain = dto.toDomain();

      expect(domain.bio, equals('Daft Punk was a French electronic music duo.'));
      expect(domain.imageUrl, equals('https://lastfm.freetls.fastly.net/mega.png'));
      expect(domain.formattedListeners, equals('4.5 M auditeurs'));
      expect(domain.formattedPlayCount, equals('180 M écoutes'));
    });

    test('cleans HTML anchor tags and boilerplate from album wiki', () {
      final json = {
        'album': {
          'name': 'Discovery',
          'listeners': '950000',
          'playcount': '25000000',
          'wiki': {
            'published': '03 Mar 2001',
            'content':
                'Discovery is the second studio album by French house duo Daft Punk. <a href="...">Read more</a>',
          },
          'image': [
            {'#text': 'https://lastfm.freetls.fastly.net/large.jpg', 'size': 'large'},
          ],
        },
      };

      final dto = LastFmAlbumDto.fromJson(json);
      final domain = dto.toDomain();

      expect(domain.name, equals('Discovery'));
      expect(domain.published, equals('03 Mar 2001'));
      expect(
        domain.wiki,
        equals('Discovery is the second studio album by French house duo Daft Punk.'),
      );
      expect(domain.formattedListeners, equals('950 k auditeurs'));
      expect(domain.formattedPlayCount, equals('25 M écoutes'));
    });
  });

  group('MetadataCacheDataSourceImpl', () {
    late Directory tempDir;
    late MetadataCacheDataSourceImpl cache;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('metadata_cache_test_');
      cache = MetadataCacheDataSourceImpl(cacheDir: tempDir);
      await cache.init();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saves and retrieves artist from disk cache', () async {
      const dto = LastFmArtistDto(
        artist: LastFmArtistData(
          stats: LastFmStatsDto(listeners: '1000', playCount: '5000'),
          bio: LastFmBioDto(content: 'Test bio', published: '2024'),
        ),
      );

      await cache.saveArtist('Stromae', dto);
      final retrieved = await cache.getArtist('Stromae');

      expect(retrieved, isNotNull);
      expect(retrieved!.artist?.bio?.content, equals('Test bio'));
      expect(retrieved.artist?.stats?.listeners, equals('1000'));
    });

    test('computes cache size and clears disk cache', () async {
      const dto = LastFmArtistDto(
        artist: LastFmArtistData(
          bio: LastFmBioDto(content: 'Short bio for testing'),
        ),
      );

      await cache.saveArtist('Orelsan', dto);
      final size = await cache.getCacheSizeBytes();
      expect(size, greaterThan(0));

      await cache.clearCache();
      final sizeAfter = await cache.getCacheSizeBytes();
      expect(sizeAfter, equals(0));
    });
  });
}
