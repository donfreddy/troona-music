abstract final class AppSpacing {
  // Grille de base 4pt — identique à iOS HIG
  static const double xs = 4.0; // séparateurs internes
  static const double sm = 8.0; // gap entre icône et texte
  static const double md = 12.0; // padding interne compact
  static const double lg = 16.0; // padding standard
  static const double xl = 20.0; // marges de page
  static const double xl2 = 24.0; // espacement entre sections
  static const double xl3 = 32.0; // grandes respirations
  static const double xl4 = 40.0; // hero spacing

  // Border radius
  static const double radiusSm = 8.0; // boutons, badges
  static const double radiusMd = 12.0; // cards secondaires
  static const double radiusLg = 16.0; // mini player, sheets
  static const double radiusXl = 20.0; // glass cards, modals
  static const double radiusFull = 999.0; // pills

  // Hauteurs de composants
  static const double trackRowHeight = 52.0;
  static const double artworkBigHeight = 50.0;
  static const double artworkSmallHeight = 126.0;
  static const double tabBarHeight = 56.0;
  static const double miniPlayerHeight = 64;
  static const double navBarHeight = 64;
  static const double bottomBlockHeight =
      miniPlayerHeight + 6 + navBarHeight; // 128px + safeArea
}
