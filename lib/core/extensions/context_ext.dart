import 'package:flutter/material.dart';

extension ContextExt on BuildContext {
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

  bool get isLandscape => MediaQuery.orientationOf(this) == Orientation.landscape;

  // ── SnackBar helper ────────────────────────────────────────────────────────

  void showSnackBar(String message, {Duration duration = const Duration(seconds: 3), SnackBarAction? action}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: duration, action: action));
  }
}
