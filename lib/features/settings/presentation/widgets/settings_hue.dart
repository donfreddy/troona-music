import 'package:flutter/painting.dart';

/// One tint per settings category, on its row at the root and on every row
/// of its page: a colour per row made the list noisy.
abstract final class SettingsHue {
  static const audio = Color(0xFF6366F1);
  static const library = Color(0xFFF59E0B);
  static const online = Color(0xFF0EA5E9);
  static const appearance = Color(0xFFEC4899);
  static const backup = Color(0xFF3B82F6);
  static const storage = Color(0xFF64748B);
  static const about = Color(0xFF10B981);
}
