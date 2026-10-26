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
          'stats': {'listeners': '4500000', 'playcount': '180000000'},
          'bio': {
            'published': '2023-01-01',
            'content':
                'Daft Punk was a French electronic music duo. <a href="https://www.last.fm/music/Daft+Punk">Read more on Last.fm</a>. User-contributed text is available under Creative Commons.',
          },
          'image': [
            {'#text': 'https://example.com/small.png', 'size': 'small'},
            {'#text': 'https://example.com/mega.png', 'size': 'mega'},
          ],
        },
      };

      final dto = LastFmArtistDto.fromJson(json);
      final domain = dto.toDomain();

      expect(
        domain.bio,
        equals('Daft Punk was a French electronic music duo.'),
      );
      expect(domain.imageUrl, equals('https://example.com/mega.png'));
      expect(domain.formattedListeners, equals('4.5 M auditeurs'));
      expect(domain.formattedPlayCount, equals('180 M écoutes'));
    });

    test(
      'parses Future response with tags, similar artists, ontour and rejects placeholder star',
      () {
        final json = {
          'artist': {
            'name': 'Future',
            'ontour': '1',
            'image': [
              {
                '#text':
                    'https://lastfm-img.freetls.fastly.net/i/u/34s/2a96cbd8b46e442fc41c2b86b821562f.png',
                'size': 'small',
              },
              {
                '#text':
                    'https://lastfm-img.freetls.fastly.net/i/u/300x300/2a96cbd8b46e442fc41c2b86b821562f.png',
                'size': 'extralarge',
              },
            ],
            'stats': {'listeners': '3381004', 'playcount': '490550591'},
            'tags': {
              'tag': [
                {'name': 'Hip-Hop', 'url': 'https://www.last.fm/tag/Hip-Hop'},
                {'name': 'rap', 'url': 'https://www.last.fm/tag/rap'},
                {'name': 'trap', 'url': 'https://www.last.fm/tag/trap'},
                {'name': 'hip hop', 'url': 'https://www.last.fm/tag/hip+hop'},
                {'name': 'atlanta', 'url': 'https://www.last.fm/tag/atlanta'},
              ],
            },
            'similar': {
              'artist': [
                {
                  'name': 'Young Thug',
                  'url': 'https://www.last.fm/music/Young+Thug',
                },
                {'name': 'DJ Esco', 'url': 'https://www.last.fm/music/DJ+Esco'},
                {'name': 'Gunna', 'url': 'https://www.last.fm/music/Gunna'},
              ],
            },
            'bio': {
              'published': '25 Dec 2012, 05:14',
              'content':
                  'Future est un rappeur américain. <a href="https://www.last.fm/music/Future">Read more on Last.fm</a>',
            },
          },
        };

        final dto = LastFmArtistDto.fromJson(json);
        final domain = dto.toDomain();

        // Placeholder hash 2a96cbd8b46e442fc41c2b86b821562f is properly rejected!
        expect(domain.imageUrl, isNull);
        expect(domain.isOnTour, isTrue);
        expect(domain.tags, containsAll(['Hip-Hop', 'Rap', 'Trap', 'Atlanta']));
        expect(domain.similarArtists.length, equals(3));
        expect(domain.similarArtists.first.name, equals('Young Thug'));
        expect(domain.formattedListeners, equals('3.4 M auditeurs'));
        expect(domain.formattedPlayCount, equals('490.6 M écoutes'));
      },
    );

    test(
      'falls back cleanly to summary when content is empty (Future & Zaytoven)',
      () {
        // Case 1: summary has text before the link
        final jsonWithText = {
          'artist': {
            'name': 'Future & Zaytoven',
            'bio': {
              'content': '',
              'summary':
                  'Future & Zaytoven est un duo de trap américain. <a href="https://www.last.fm/music/Future+&+Zaytoven">Read more on Last.fm</a>',
            },
          },
        };
        final dto1 = LastFmArtistDto.fromJson(jsonWithText);
        expect(
          dto1.toDomain().bio,
          equals('Future & Zaytoven est un duo de trap américain.'),
        );
        expect(
          dto1.toDomain().lastFmUrl,
          equals('https://www.last.fm/music/Future+&+Zaytoven'),
        );

        // Case 2: summary only has the link "<a href="...">Read more on Last.fm</a>"
        final jsonOnlyLink = {
          'artist': {
            'name': 'Future & Zaytoven',
            'bio': {
              'content': '',
              'summary':
                  ' <a href="https://www.last.fm/music/Future+&+Zaytoven">Read more on Last.fm</a>',
            },
          },
        };
        final dto2 = LastFmArtistDto.fromJson(jsonOnlyLink);
        expect(
          dto2.toDomain().bio,
          equals('Consulter la page complète sur Last.fm.'),
        );
        expect(
          dto2.toDomain().lastFmUrl,
          equals('https://www.last.fm/music/Future+&+Zaytoven'),
        );
      },
    );

    test(
      'returns null bio for [unknown] and eliminates residual dots from CC boilerplate',
      () {
        final json = {
          'artist': {
            'name': '[unknown]',
            'bio': {
              'summary':
                  ' <a href="https://www.last.fm/music/%5Bunknown%5D">Read more on Last.fm</a>',
              'content':
                  ' <a href="https://www.last.fm/music/%5Bunknown%5D">Read more on Last.fm</a>. User-contributed text is available under the Creative Commons By-SA License; additional terms may apply.',
            },
          },
        };
        final dto = LastFmArtistDto.fromJson(json);
        expect(dto.toDomain().bio, isNull);
      },
    );

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
          'tags': {
            'tag': [
              {'name': 'electronic'},
              {'name': 'french house'},
            ],
          },
          'image': [
            {'#text': 'https://example.com/large.jpg', 'size': 'large'},
          ],
        },
      };

      final dto = LastFmAlbumDto.fromJson(json);
      final domain = dto.toDomain();

      expect(domain.name, equals('Discovery'));
      expect(domain.published, equals('03 Mar 2001'));
      expect(
        domain.wiki,
        equals(
          'Discovery is the second studio album by French house duo Daft Punk.',
        ),
      );
      expect(domain.formattedListeners, equals('950 k auditeurs'));
      expect(domain.formattedPlayCount, equals('25 M écoutes'));
      expect(domain.tags, containsAll(['Electronic', 'French House']));
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

    test('saves and retrieves rich artist from disk cache', () async {
      const dto = LastFmArtistDto(
        artist: LastFmArtistData(
          stats: LastFmStatsDto(listeners: '1000', playCount: '5000'),
          bio: LastFmBioDto(content: 'Test bio', published: '2024'),
          tags: ['Trap', 'Hip-Hop'],
          isOnTour: true,
          customImageUrl:
              'https://e-cdns-images.dzcdn.net/images/artist/123/1000x1000.jpg',
          similar: [LastFmSimilarArtistDto(name: 'Young Thug')],
        ),
      );

      await cache.saveArtist('Future', dto);
      final retrieved = await cache.getArtist('Future');

      expect(retrieved, isNotNull);
      expect(retrieved!.artist?.bio?.content, equals('Test bio'));
      expect(retrieved.artist?.stats?.listeners, equals('1000'));
      expect(retrieved.artist?.tags, equals(['Trap', 'Hip-Hop']));
      expect(retrieved.artist?.isOnTour, isTrue);
      expect(
        retrieved.artist?.customImageUrl,
        equals(
          'https://e-cdns-images.dzcdn.net/images/artist/123/1000x1000.jpg',
        ),
      );
      expect(retrieved.artist?.similar.first.name, equals('Young Thug'));
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
