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
      mediaStoreId: map['mediaStoreId'] as String?,
      name: map['name'] as String?,
      size: size is int ? size : null,
    );
  }
}
