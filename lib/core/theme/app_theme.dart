import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:troona/core/theme/primitives/color_primitives.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final base = isDark ? ThemeData.dark() : ThemeData.light();

    return base.copyWith(
      brightness: brightness,
      // ignore: deprecated_member_use
      useMaterial3: true,

      // Palette Material → tokens iOS
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.accent,
        onPrimary: colors.accentForeground,
        secondary: colors.accent,
        onSecondary: colors.accentForeground,
        surface: colors.bgSecondary,
        onSurface: colors.labelPrimary,
        error: const Color(0xFFFF3B30), // systemRed iOS
        onError: ColorPrimitives.white,
        // ... autres rôles
      ),

      scaffoldBackgroundColor: colors.bgPrimary,
      canvasColor: colors.bgPrimary,
      cardColor: colors.bgSecondary,
      dividerColor: colors.separator,

      textTheme: AppTypography.textTheme.apply(
        bodyColor: colors.labelPrimary,
        displayColor: colors.labelPrimary,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: AppTypography.textTheme.headlineSmall?.copyWith(
          color: colors.labelPrimary,
        ),
        iconTheme: IconThemeData(color: colors.accent),
      ),

      // Page transitions iOS
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),

      // Extensions custom
      extensions: [colors],
    );
  }
}
