import 'package:flutter/services.dart';

/// Haptic feedback, off when the user turns it off in Settings: never call
/// [HapticFeedback] directly. One vocabulary across the app:
///
/// - [selectionClick]: a choice among options (a segment, a sort) and a
///   swipe that becomes armed.
/// - [lightImpact]: a small step (skip, open a menu, refresh, a like by
///   long press on the mini player).
/// - [mediumImpact]: playback starts or stops (Play, Shuffle, play/pause,
///   the album's record).
/// - Nothing while scrolling or dragging.
///
/// Playback ticks once, in `PlayerBloc`, whatever started it: a button that
/// sends a playback event adds no tick of its own.
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
