import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioPermissionHandler {
  static Future<bool> requestAudioPermission() async {
    if (Platform.isAndroid) {
      // Android 13+ : READ_MEDIA_AUDIO remplace READ_EXTERNAL_STORAGE
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final permission = androidInfo.version.sdkInt >= 33
          ? Permission
                .audio // READ_MEDIA_AUDIO
          : Permission.storage; // READ_EXTERNAL_STORAGE (≤ Android 12)

      final status = await permission.request();
      return status.isGranted;
    }

    if (Platform.isIOS) {
      // iOS : accès à la bibliothèque musicale
      final status = await Permission.mediaLibrary.request();
      return status.isGranted;
    }

    return false;
  }
}
