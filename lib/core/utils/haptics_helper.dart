import 'package:flutter/services.dart';

/// Helper to provide consistent haptic feedback across the app.
class AppHaptics {
  const AppHaptics._();

  /// Very light tap for subtle actions (e.g., play/pause).
  static Future<void> lightImpact() => HapticFeedback.lightImpact();

  /// Medium impact for more significant actions (e.g., skip).
  static Future<void> mediumImpact() => HapticFeedback.mediumImpact();

  /// Heavy impact for destructive or major actions.
  static Future<void> heavyImpact() => HapticFeedback.heavyImpact();

  /// Selection click feedback.
  static Future<void> selectionClick() => HapticFeedback.selectionClick();
}
