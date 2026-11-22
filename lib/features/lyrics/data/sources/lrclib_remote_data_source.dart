import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:troona/core/utils/sort_key.dart';
import 'package:troona/features/lyrics/data/sources/lyrics_query.dart';
import 'package:troona/features/lyrics/data/sources/lyrics_remote_source.dart';
import 'package:troona/features/lyrics/domain/services/lrc_parser.dart';

/// LRCLIB (lrclib.net), a free database of synced lyrics.
///
/// First the exact song (title, artist, album, length); LRCLIB answers it
/// only when the album matches too, which a folder name standing in for an
/// album never does. Then a search by title and artist, taking the song of
/// the same name whose length is within [tolerance]: its timings fit. With
/// none that long, the words of a song of the same name and artist, never
/// its timings (another cut, a radio edit). Better no lyrics than another
/// song's.
final class LrclibRemoteDataSource implements LyricsRemoteSource {
  final Dio _dio;

  LrclibRemoteDataSource(this._dio);

  static const base = 'https://lrclib.net/api';

  /// LRCLIB asks clients to say who they are.
  static const userAgent = 'Troona (https://github.com/donfreddy/troona-music)';

  /// How far a song's length may be from the lyrics' for their timings to
  /// fit.
  static const tolerance = Duration(seconds: 2);

  @override
  Future<String?> find(LyricsQuery query) async {
    if (query.title.isEmpty) return null;
    if (query.artist.isNotEmpty &&
        query.album.isNotEmpty &&
        query.duration > Duration.zero) {
      final exact = await _call('/get', {
        'track_name': query.title,
        'artist_name': query.artist,
        'album_name': query.album,
        'duration': query.duration.inSeconds,
      });
      if (exact is Map) {
        if (exact['instrumental'] == true) return null;
        final text =
            _text(exact['syncedLyrics']) ?? _text(exact['plainLyrics']);
        if (text != null) return text;
      }
    }
    final found = await _call('/search', {
      'track_name': query.plainTitle,
      if (query.leadArtist.isNotEmpty) 'artist_name': query.leadArtist,
    });
    return found is List ? pick(found, query) : null;
  }

  /// The lyrics among LRCLIB's search [results] that fit [query], as above.
  @visibleForTesting
  static String? pick(List<Object?> results, LyricsQuery query) {
    final same = [
      for (final r in results)
        if (r is Map &&
            r['instrumental'] != true &&
            r['trackName'] is String &&
            _sameName(r['trackName'] as String, query.title))
          r,
    ];
    if (query.duration > Duration.zero) {
      Duration gap(Map r) {
        final seconds = r['duration'];
        if (seconds is! num) return const Duration(days: 1);
        return (Duration(milliseconds: (seconds * 1000).round()) -
                query.duration)
            .abs();
      }

      final fit = [
        for (final r in same)
          if (gap(r) <= tolerance) r,
      ]..sort((a, b) => gap(a).compareTo(gap(b)));
      for (final r in fit) {
        if (_text(r['syncedLyrics']) case final synced?) return synced;
      }
      for (final r in fit) {
        if (_text(r['plainLyrics']) case final plain?) return plain;
      }
    }
    if (query.leadArtist.isEmpty) return null;
    for (final r in same) {
      final artist = r['artistName'];
      if (artist is! String || !_sameArtist(artist, query.leadArtist)) {
        continue;
      }
      if (_text(r['plainLyrics']) case final plain?) return plain;
    }
    return null;
  }

  /// LRCLIB's answer: the body, null when it has no such song.
  Future<Object?> _call(String path, Map<String, Object> params) async {
    final Response<Object?> response;
    try {
      response = await _dio.get<Object?>(
        '$base$path',
        queryParameters: params,
        options: Options(
          headers: const {'User-Agent': userAgent},
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null,
        ),
      );
    } on DioException catch (e) {
      throw LyricsUnreachable('LRCLIB: ${e.type.name}');
    }
    final status = response.statusCode ?? 0;
    if (status == 404) return null;
    if (status != 200) throw LyricsUnreachable('LRCLIB: HTTP $status');
    final body = response.data;
    if (body is! String) return body;
    try {
      return jsonDecode(body);
    } on FormatException {
      throw const LyricsUnreachable('LRCLIB: not JSON');
    }
  }

  static String? _text(Object? value) =>
      value is String &&
          value.trim().isNotEmpty &&
          value.length <= LrcParser.maxBytes
      ? value
      : null;

  static final _notWord = RegExp(r'[^\p{L}\p{N}]', unicode: true);

  static String _key(String name) =>
      foldedKey(LyricsQuery.plainTitleOf(name)).replaceAll(_notWord, '');

  static bool _sameName(String a, String b) => _key(a) == _key(b);

  /// [artist] names [lead], alone or with others ("Queen & David Bowie"),
  /// as whole words: "Ye" is not in "Kanye West".
  static bool _sameArtist(String artist, String lead) {
    final key = foldedKey(lead);
    if (key.isEmpty) return false;
    return RegExp(
      '(^|[^\\p{L}\\p{N}])${RegExp.escape(key)}(\$|[^\\p{L}\\p{N}])',
      unicode: true,
    ).hasMatch(foldedKey(artist));
  }
}
