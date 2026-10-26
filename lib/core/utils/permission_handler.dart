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

  static bool? _cachedPermission;

  /// Invalidates the cached permission result so the next [hasAudioPermission]
  /// call re-queries the OS. Call on AppLifecycleState.resumed.
  static void invalidateCache() => _cachedPermission = null;

  /// Returns the Android SDK version, or 0 on non-Android platforms.
  static Future<int> _androidSdkInt() async {
    if (!Platform.isAndroid) return 0;
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt;
  }

  /// Resolves the correct [Permission] for the running platform/SDK.
  static Future<Permission> _resolvePermission(int sdkInt) async {
    if (Platform.isAndroid) {
      return sdkInt >= 33
          ? Permission.audio // READ_MEDIA_AUDIO  (API 33+)
          : Permission.storage; // READ_EXTERNAL_STORAGE (API <= 32)
    }
    return Permission.mediaLibrary; // iOS
  }

  /// Requests audio permission and returns `true` if granted.
  /// Throws [PermissionException] on denial or permanent denial.
  static Future<bool> requestAudioPermission() async {
    final sdkInt = await _androidSdkInt();
    final permission = await _resolvePermission(sdkInt);
    final status = await permission.request();

    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited: // iOS limited library access
        // on_audio_query uses READ_EXTERNAL_STORAGE internally.
        // On API 33+, that permission is deprecated and not requestable, so
        // skip the plugin check entirely: READ_MEDIA_AUDIO is sufficient.
        if (Platform.isAndroid && sdkInt < 33) {
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
        throw const PermissionPermanentlyDeniedException();

      case PermissionStatus.denied:
      default:
        throw const PermissionException(
          'Audio permission denied. Please grant access in Settings.',
        );
    }
  }

  /// Non-throwing check — `true` if permission is already granted.
  ///
  /// Result is cached in memory; call [invalidateCache] (e.g. on
  /// AppLifecycleState.resumed) to force a fresh OS query.
  static Future<bool> hasAudioPermission() async {
    if (_cachedPermission != null) return _cachedPermission!;

    final sdkInt = await _androidSdkInt();
    final permission = await _resolvePermission(sdkInt);
    final status = await permission.status;
    final granted =
        status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
    if (!granted) {
      _cachedPermission = false;
      return false;
    }

    // On API 33+, READ_MEDIA_AUDIO being granted is sufficient — skip the
    // plugin's internal READ_EXTERNAL_STORAGE check which returns false on
    // API 33+ and would incorrectly report "not granted".
    final result =
        Platform.isAndroid && sdkInt < 33
            ? await _audioQuery.permissionsStatus()
            : true;
    _cachedPermission = result;
    return result;
  }
}
