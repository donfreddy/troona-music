import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:troona/features/lyrics/data/sources/lyrics_query.dart';
import 'package:troona/features/lyrics/data/sources/lyrics_remote_source.dart';
import 'package:troona/features/lyrics/domain/services/lrc_parser.dart';

/// lyrics.ovh, asked when LRCLIB has nothing: plain lyrics only, found by
/// artist and title.
final class LyricsOvhRemoteDataSource implements LyricsRemoteSource {
  final Dio _dio;

  LyricsOvhRemoteDataSource(this._dio);

  static const base = 'https://api.lyrics.ovh/v1';

  @override
  Future<String?> find(LyricsQuery query) async {
    if (query.leadArtist.isEmpty || query.plainTitle.isEmpty) return null;
    final url =
        '$base/${Uri.encodeComponent(query.leadArtist)}'
        '/${Uri.encodeComponent(query.plainTitle)}';
    final Response<Object?> response;
    try {
      response = await _dio.get<Object?>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null,
        ),
      );
    } on DioException catch (e) {
      throw LyricsUnreachable('lyrics.ovh: ${e.type.name}');
    }
    final status = response.statusCode ?? 0;
    if (status == 404) return null;
    if (status != 200) throw LyricsUnreachable('lyrics.ovh: HTTP $status');
    final body = response.data;
    try {
      final json = body is String ? jsonDecode(body) : body;
      return json is Map ? clean(json['lyrics']) : null;
    } on FormatException {
      throw const LyricsUnreachable('lyrics.ovh: not JSON');
    }
  }

  static final _heading = RegExp(r'^Paroles de la chanson .+ par .+$');

  /// The lyrics in [value], without the heading lyrics.ovh puts before
  /// some ("Paroles de la chanson X par Y"); null when none are left.
  @visibleForTesting
  static String? clean(Object? value) {
    if (value is! String || value.length > LrcParser.maxBytes) return null;
    final lines = const LineSplitter().convert(value);
    if (lines.isNotEmpty && _heading.hasMatch(lines.first.trim())) {
      lines.removeAt(0);
    }
    final text = lines.join('\n').trim();
    return text.isEmpty ? null : text;
  }
}
