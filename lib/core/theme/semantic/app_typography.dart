import 'package:flutter/material.dart';

abstract final class AppTypography {
  // Flutter n'a pas SF Pro en natif.
  // Sur iOS : le système utilise SF Pro automatiquement si fontFamily est null.
  // Sur Android : on embarque une Google Font proche (Nunito ou DM Sans).
  //static const _fontFamily = null; // null = SF Pro sur iOS

  static TextTheme get textTheme => const TextTheme(
    // Large Title — titre de page (scroll collapse)
    displayLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.37,
      height: 1.21,
    ),

    // Title 1 — titres de section
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.36,
      height: 1.21,
    ),

    // Title 2
    displaySmall: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.35,
      height: 1.27,
    ),

    // Title 3
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.38,
      height: 1.3,
    ),

    // Headline
    headlineSmall: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.41,
      height: 1.29,
    ),

    // Body — texte principal
    bodyLarge: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.41,
      height: 1.29,
    ),

    // Callout
    bodyMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.32,
      height: 1.31,
    ),

    // Subheadline
    bodySmall: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.24,
      height: 1.33,
    ),

    // Footnote
    labelLarge: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.08,
      height: 1.38,
    ),

    // Caption 1
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.33,
    ),

    // Caption 2
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.07,
      height: 1.45,
    ),
  );
}
