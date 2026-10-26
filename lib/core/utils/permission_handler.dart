import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart'
    hide AlbumModel, ArtistModel;
import 'package:permission_handler/permission_handler.dart';
import 'package:troona/core/error/exceptions.dart';

/// Requests and checks audio-related storage permissions.
/// Throws [PermissionException] if the user denies or permanently denies.
abstract final class AppPermissionHandler {
  AppPermissionHandler._();

  static final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Resolves the correct [Permission] for the running platform/SDK.
  /// Async because Android SDK version requires a device info call.
  static Future<Permission> _resolvePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 33
          ? Permission
                .audio // READ_MEDIA_AUDIO  (API 33+)
          : Permission.storage; // READ_EXTERNAL_STORAGE (API ≤ 32)
    }
    return Permission.mediaLibrary; // iOS
  }

  /// Requests audio permission and returns `true` if granted.
  /// Throws [PermissionException] on denial or permanent denial.
  static Future<bool> requestAudioPermission() async {
    final permission = await _resolvePermission();
    final status = await permission.request();

    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited: // iOS limited library access
        if (Platform.isAndroid) {
          final pluginGranted =
              await _audioQuery.permissionsStatus() ||
              await _audioQuery.permissionsRequest();
          if (!pluginGranted) {
            throw const PermissionException(
              'Audio permission denied. Please grant access in Settings.',
            );
          }
        }
        return true;

      case PermissionStatus.permanentlyDenied:
        await openAppSettings();
        throw const PermissionException('Audio permission permanently denied.');

      case PermissionStatus.denied:
      default:
        throw const PermissionException(
          'Audio permission denied. Please grant access in Settings.',
        );
    }
  }

  /// Non-throwing check — `true` if permission is already granted.
  static Future<bool> hasAudioPermission() async {
    final permission = await _resolvePermission();
    final status = await permission.status;
    final granted =
        status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
    if (!granted) return false;

    if (Platform.isAndroid) {
      return _audioQuery.permissionsStatus();
    }

    return true;
  }
}
