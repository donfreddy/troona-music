abstract final class AppSpacing {
  // 4 pt base grid, as in the iOS HIG
  static const double xs = 4.0; // inner separators
  static const double sm = 8.0; // gap between icon and text
  static const double md = 12.0; // compact inner padding
  static const double lg = 16.0; // padding standard
  static const double xl = 20.0; // page margins
  static const double xl2 = 24.0; // space between sections
  static const double xl3 = 32.0; // large breathing room
  static const double xl4 = 40.0; // hero spacing

  // Border radius
  static const double radiusSm = 8.0; // buttons, badges
  static const double radiusMd = 12.0; // secondary cards
  static const double radiusLg = 16.0; // mini player, sheets
  static const double radiusXl = 20.0; // glass cards, modals
  static const double radiusFull = 999.0; // pills

  // Component heights
  static const double trackRowHeight = 52.0;
  static const double artworkBigHeight = 50.0;
  static const double artworkSmallHeight = 126.0;
  static const double tabBarHeight = 56.0;
  static const double miniPlayerHeight = 64;
  static const double navBarHeight = 64;
  static const double bottomBlockHeight =
      miniPlayerHeight + 6 + navBarHeight; // 128px + safeArea
}
