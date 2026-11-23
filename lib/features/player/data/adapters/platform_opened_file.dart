import 'dart:async';

import 'package:flutter/services.dart';
import 'package:troona/core/utils/app_logger.dart';
import 'package:troona/features/player/domain/entities/opened_audio.dart';
import 'package:troona/features/player/domain/ports/opened_file_port.dart';

/// [OpenedFilePort] over the Android activity's channel
/// (`OpenedFileChannel.kt`). Any failure of the channel (no activity, as
/// when `audio_service` starts the app with none; another platform) means
/// no file opened.
final class PlatformOpenedFile implements OpenedFilePort {
  static const channel = MethodChannel('troona/opened_file');

  final _offered = StreamController<void>.broadcast();

  PlatformOpenedFile() {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'offered') _offered.add(null);
    });
  }

  @override
  Stream<void> get offered => _offered.stream;

  @override
  Future<OpenedFileRequest?> take() async {
    try {
      final map = await channel.invokeMapMethod<String, Object?>('take');
      return map == null ? null : requestOf(map);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      appLogger.w('Opened file not taken: $e');
      return null;
    }
  }

  /// The request the channel describes; null without an address.
  static OpenedFileRequest? requestOf(Map<String, Object?> map) {
    final uri = map['uri'];
    if (uri is! String || uri.isEmpty) return null;
    final size = map['size'];
    return OpenedFileRequest(
      uri: uri,
      mediaStoreId: mediaStoreIdOf(uri),
      name: map['name'] as String?,
      size: size is int ? size : null,
    );
  }

  static const _documentPrefixes = {
    'com.android.providers.media.documents': 'audio:',
    'com.android.providers.downloads.documents': 'msf:',
  };

  /// The MediaStore id [address] carries, the library's `Track.id`: a
  /// MediaStore address of the external volumes (`.../audio/media/<id>`), or
  /// a document of the media (`audio:<id>`) or downloads (`msf:<id>`, a
  /// MediaStore file, whose id the audio table shares) providers. Null
  /// otherwise: the internal volume (ringtones, system sounds) counts its
  /// ids apart, and a downloads id of its own is not MediaStore's.
  static String? mediaStoreIdOf(String address) {
    final uri = Uri.tryParse(address);
    if (uri == null || uri.scheme != 'content') return null;
    final segments = uri.pathSegments;
    if (uri.host == 'media') {
      if (segments.isEmpty || segments.first == 'internal') return null;
      final at = segments.indexOf('audio');
      if (at < 0 || at + 2 >= segments.length) return null;
      return segments[at + 1] == 'media' ? _digits(segments[at + 2]) : null;
    }
    final prefix = _documentPrefixes[uri.host];
    final at = segments.lastIndexOf('document');
    if (prefix == null || at < 0 || at + 1 >= segments.length) return null;
    final id = segments[at + 1];
    return id.startsWith(prefix) ? _digits(id.substring(prefix.length)) : null;
  }

  static String? _digits(String s) =>
      s.isNotEmpty && s.codeUnits.every((c) => c >= 48 && c <= 57) ? s : null;
}
