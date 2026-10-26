import 'package:flutter/material.dart';
import 'package:troona/l10n/app_localizations.dart';

extension ContextExt on BuildContext {
  /// UI strings for the current locale.
  AppLocalizations get l10n => AppLocalizations.of(this);

  // ── Theme shortcuts ────────────────────────────────────────────────────────

  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  // ── Media query shortcuts ──────────────────────────────────────────────────

  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  double get bottomPadding => padding.bottom;

  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;
}
