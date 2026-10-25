import 'dart:ui' as ui;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';

/// Detects the appropriate [GlassQuality] tier at startup using hardware signals.
///
/// Call [detect] once from [configureDependencies] before the first frame.
/// The result is stored in [detected] and consumed by [GlassTheme].
abstract final class GlassTier {
  static GlassQuality _detected = GlassQuality.high;

  static GlassQuality get detected => _detected;

  static Future<void> detect() async {
    if (ui.PlatformDispatcher.instance.accessibilityFeatures.disableAnimations) {
      _detected = GlassQuality.off;
      return;
    }

    try {
      final info = await DeviceInfoPlugin().androidInfo;
      final ramMb = info.physicalRamSize;
      final sdkInt = info.version.sdkInt;

      if (ramMb < 3072) {
        _detected = GlassQuality.off;
      } else if (ramMb < 6144 || sdkInt < 29) {
        _detected = GlassQuality.low;
      } else {
        _detected = GlassQuality.high;
      }
    } catch (_) {
      _detected = GlassQuality.high;
    }
  }
}
