import 'package:flutter/widgets.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';

/// Troona lays out from the room each screen has, never by scaling a design
/// size: a short phone gets a smaller Now Playing ring, not smaller buttons.
abstract final class AppLayout {
  /// Fixed-height chrome follows the phone's font size up to this factor:
  /// the tab bar with the mini player, Now Playing and its queue, and the
  /// Library filter in its pinned header. Now Playing is checked at it on a
  /// 360 x 640 screen. Everything else follows the font size fully, up to
  /// 2.0, and stacks or wraps where a row would not fit.
  static const maxTextScale = 1.3;
}

extension AppLayoutContext on BuildContext {
  /// Bottom padding for content scrolling under the floating bar: the mini
  /// player and the tabs on root pages, the mini player alone on detail
  /// pages ([tabs] false).
  double bottomBarInset({bool tabs = true}) =>
      (tabs ? AppSpacing.bottomBlockHeight : AppSpacing.miniPlayerHeight) +
      MediaQuery.paddingOf(this).bottom +
      AppSpacing.xl;
}
