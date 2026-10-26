import 'package:flutter/services.dart';

/// Helper to provide consistent haptic feedback across the app.
class AppHaptics {
  const AppHaptics._();

  /// Static flag reflecting user preference. When false, all calls are no-ops.
  static bool enabled = true;

  /// Very light tap for subtle actions (e.g., play/pause).
  static Future<void> lightImpact() {
    if (!enabled) return Future.value();
    return HapticFeedback.lightImpact();
  }

  /// Medium impact for more significant actions (e.g., skip).
  static Future<void> mediumImpact() {
    if (!enabled) return Future.value();
    return HapticFeedback.mediumImpact();
  }

  /// Heavy impact for destructive or major actions.
  static Future<void> heavyImpact() {
    if (!enabled) return Future.value();
    return HapticFeedback.heavyImpact();
  }

  /// Selection click feedback.
  static Future<void> selectionClick() {
    if (!enabled) return Future.value();
    return HapticFeedback.selectionClick();
  }
}
