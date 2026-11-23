import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/lyrics/data/sources/lrclib_remote_data_source.dart';
import 'package:troona/features/lyrics/data/sources/lyrics_ovh_remote_data_source.dart';
import 'package:troona/features/lyrics/data/sources/lyrics_query.dart';
import 'package:troona/features/lyrics/data/sources/lyrics_remote_source.dart';

import '../../helpers/fake_player.dart';

/// Answers each request with [answer], or throws a connection error when it
/// returns null.
class _Server implements HttpClientAdapter {
  ResponseBody? Function(RequestOptions) answer;
  final requests = <RequestOptions>[];

  _Server(this.answer);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = answer(options);
    if (body == null) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return body;
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object? body, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Map<String, Object?> _hit({
  String track = 'Love Me JeJe',
  String artist = 'Tems',
  num duration = 178,
  String? synced = '[00:01.00]Synced',
  String? plain = 'Plain',
  bool instrumental = false,
}) => {
  'trackName': track,
  'artistName': artist,
  'duration': duration,
  'instrumental': instrumental,
  'syncedLyrics': synced,
  'plainLyrics': plain,
};

LyricsQuery _query({
  String title = 'Love Me JeJe',
  String artist = 'Tems',
  String album = 'Born in the Wild',
  int seconds = 178,
}) => LyricsQuery(
  title: title,
  plainTitle: LyricsQuery.plainTitleOf(title),
  artist: artist,
  leadArtist: artist,
  album: album,
  duration: Duration(seconds: seconds),
);

void main() {
  group('plain title', () {
    for (final (title, plain) in [
      ('Bohemian Rhapsody (Remastered 2011)', 'Bohemian Rhapsody'),
      ('Bohemian Rhapsody - Remastered 2011', 'Bohemian Rhapsody'),
      ('Essence (feat. Tems)', 'Essence'),
      ('Essence [ft. Tems]', 'Essence'),
      ('Essence feat. Tems', 'Essence'),
      ('Song (Official Video)', 'Song'),
      ('Song (Live at Wembley)', 'Song'),
      ('Song (Radio Mix)', 'Song'),
      // A remix often has verses of its own: its own lyrics.
      ('Ojuelegba (Remix)', 'Ojuelegba (Remix)'),
      // A bracket that is part of the title stays.
      ('(I Can\'t Get No) Satisfaction', '(I Can\'t Get No) Satisfaction'),
      ('Love Me JeJe', 'Love Me JeJe'),
      // Nothing would be left: the title itself.
      ('(Live)', '(Live)'),
    ]) {
      test('"$title" -> "$plain"', () {
        expect(LyricsQuery.plainTitleOf(title), plain);
      });
    }
  });

  group('query of a song', () {
    test('an unknown artist is sent as none', () {
      final q = LyricsQuery.of(testTrack('a', durationMs: 1000, artist: ''));
      expect(q.artist, '');
      expect(q.leadArtist, '');
    });
  });

  group('LRCLIB pick', () {
    test('synced within 2 s first, closest first', () {
      final picked = LrclibRemoteDataSource.pick([
        _hit(duration: 176, synced: '[00:01.00]Far'),
        _hit(duration: 179, synced: null, plain: 'Close plain'),
        _hit(duration: 177, synced: '[00:01.00]Near'),
      ], _query());
      expect(picked, '[00:01.00]Near');
    });

    test('plain within 2 s when none is synced', () {
      final picked = LrclibRemoteDataSource.pick([
        _hit(duration: 179, synced: null, plain: 'Close plain'),
      ], _query());
      expect(picked, 'Close plain');
    });

    test('none within 2 s: the words of the same song, never its '
        'timings', () {
      final picked = LrclibRemoteDataSource.pick([
        _hit(duration: 200, synced: '[00:01.00]Other cut', plain: 'Words'),
      ], _query());
      expect(picked, 'Words');
    });

    test('another title is never taken, even at the right length', () {
      final picked = LrclibRemoteDataSource.pick([
        _hit(track: 'Free Mind', duration: 178),
      ], _query());
      expect(picked, isNull);
    });

    test('titles match case, accents, punctuation and versions aside', () {
      final picked = LrclibRemoteDataSource.pick([
        _hit(track: 'love me jéjé!', synced: '[00:01.00]Yes'),
      ], _query(title: 'Love Me JeJe (Remastered)'));
      expect(picked, '[00:01.00]Yes');
    });

    test('words from another length need the same artist, as a whole '
        'word', () {
      final query = _query(artist: 'Ye', seconds: 300);
      expect(
        LrclibRemoteDataSource.pick([
          _hit(artist: 'Kanye West', duration: 200),
        ], query),
        isNull,
      );
      expect(
        LrclibRemoteDataSource.pick([
          _hit(artist: 'Ye & Ty Dolla \$ign', duration: 200),
        ], query),
        'Plain',
      );
    });

    test('another artist is never taken, even at the right length and '
        'with timings', () {
      expect(
        LrclibRemoteDataSource.pick([
          _hit(artist: 'Someone Else', synced: '[00:01.00]Cover'),
        ], _query()),
        isNull,
      );
    });

    test('an unknown artist takes nothing: a title alone finds any '
        'song', () {
      final query = _query(artist: '');
      expect(LrclibRemoteDataSource.pick([_hit()], query), isNull);
    });

    test('instrumentals are skipped', () {
      expect(
        LrclibRemoteDataSource.pick([_hit(instrumental: true)], _query()),
        isNull,
      );
    });
  });

  group('LRCLIB requests', () {
    late _Server server;
    late LrclibRemoteDataSource lrclib;

    setUp(() {
      server = _Server((_) => _json({'message': 'not found'}, 404));
      lrclib = LrclibRemoteDataSource(Dio()..httpClientAdapter = server);
    });

    test('the exact song first, saying who asks', () async {
      server.answer = (_) => _json(_hit());
      expect(await lrclib.find(_query()), '[00:01.00]Synced');
      final get = server.requests.single;
      expect(get.uri.path, '/api/get');
      expect(get.uri.queryParameters, {
        'track_name': 'Love Me JeJe',
        'artist_name': 'Tems',
        'album_name': 'Born in the Wild',
        'duration': '178',
      });
      expect(get.headers['User-Agent'], LrclibRemoteDataSource.userAgent);
    });

    test('then a search by title and artist', () async {
      server.answer = (o) => o.uri.path == '/api/search'
          ? _json([_hit()])
          : _json({'message': 'not found'}, 404);
      expect(
        await lrclib.find(_query(title: 'Love Me JeJe (feat. X)')),
        '[00:01.00]Synced',
      );
      final search = server.requests.last;
      expect(search.uri.queryParameters, {
        'track_name': 'Love Me JeJe',
        'artist_name': 'Tems',
      });
    });

    test('nothing anywhere is a miss', () async {
      server.answer = (o) => o.uri.path == '/api/search'
          ? _json(<Object>[])
          : _json({'message': 'not found'}, 404);
      expect(await lrclib.find(_query()), isNull);
    });

    test('an instrumental found exactly is a miss, with no search', () async {
      server.answer = (_) => _json(_hit(instrumental: true));
      expect(await lrclib.find(_query()), isNull);
      expect(server.requests, hasLength(1));
    });

    test('an unknown artist is not asked about', () async {
      server.answer = (_) => _json(_hit());
      expect(await lrclib.find(_query(artist: '')), isNull);
      expect(server.requests, isEmpty);
    });

    test('the exact song unreachable: the search is still asked, and '
        'its answer taken', () async {
      server.answer = (o) =>
          o.uri.path == '/api/search' ? _json([_hit()]) : _json({}, 503);
      expect(await lrclib.find(_query()), '[00:01.00]Synced');
      expect(server.requests, hasLength(2));
    });

    test('the exact song unreachable and nothing in the search: '
        'unreachable, not a miss', () async {
      server.answer = (o) =>
          o.uri.path == '/api/search' ? _json(<Object>[]) : _json({}, 503);
      await expectLater(
        lrclib.find(_query()),
        throwsA(isA<LyricsUnreachable>()),
      );
    });

    test('a song of unknown length goes straight to the search', () async {
      server.answer = (_) => _json(<Object>[]);
      await lrclib.find(_query(seconds: 0));
      expect(server.requests.single.uri.path, '/api/search');
    });

    for (final (what, answer) in [
      ('no network', (RequestOptions _) => null),
      ('over quota', (RequestOptions _) => _json({}, 429)),
      ('a server error', (RequestOptions _) => _json({}, 503)),
      (
        'a body that is not JSON',
        (RequestOptions _) => ResponseBody.fromString('<html>', 200),
      ),
    ]) {
      test('$what: unreachable, not a miss', () async {
        server.answer = answer;
        await expectLater(
          lrclib.find(_query()),
          throwsA(isA<LyricsUnreachable>()),
        );
      });
    }
  });

  group('lyrics.ovh', () {
    late _Server server;
    late LyricsOvhRemoteDataSource ovh;

    setUp(() {
      server = _Server((_) => _json({'lyrics': 'Line one\nLine two'}));
      ovh = LyricsOvhRemoteDataSource(Dio()..httpClientAdapter = server);
    });

    test('asks by lead artist and plain title', () async {
      expect(
        await ovh.find(_query(title: 'Song / Two (Live)', artist: 'AC/DC')),
        'Line one\nLine two',
      );
      expect(
        server.requests.single.uri.toString(),
        'https://api.lyrics.ovh/v1/AC%2FDC/Song%20%2F%20Two',
      );
    });

    test('no artist: not asked', () async {
      expect(await ovh.find(_query(artist: '')), isNull);
      expect(server.requests, isEmpty);
    });

    test('404 is a miss, 5xx and no network are unreachable', () async {
      server.answer = (_) => _json({'error': 'No lyrics found'}, 404);
      expect(await ovh.find(_query()), isNull);
      server.answer = (_) => _json({}, 502);
      await expectLater(ovh.find(_query()), throwsA(isA<LyricsUnreachable>()));
      server.answer = (_) => null;
      await expectLater(ovh.find(_query()), throwsA(isA<LyricsUnreachable>()));
    });

    test('its French heading is left out; empty lyrics are none', () {
      expect(
        LyricsOvhRemoteDataSource.clean(
          'Paroles de la chanson Djadja par Aya Nakamura\r\nLine one',
        ),
        'Line one',
      );
      expect(LyricsOvhRemoteDataSource.clean('  \n '), isNull);
      expect(LyricsOvhRemoteDataSource.clean(null), isNull);
    });
  });
}
