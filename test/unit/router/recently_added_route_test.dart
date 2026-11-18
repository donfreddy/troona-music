import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/router/app_router.dart';

void main() {
  // Home's chip and Search's suggestions push it in their own tab
  // (`pushRecentlyAdded`): both tabs declare it.
  for (final tab in [AppRoute.home, AppRoute.search]) {
    test('$tab/recent is Recently added', () {
      final match = appRouter.configuration.findMatch(Uri.parse('$tab/recent'));
      expect(match.last.route.path, 'recent');
    });
  }

  // Home's Recently added row: a sibling of `recent`, so the songs' page
  // is not built under it.
  test('/home/recent/albums is Recent albums, alone', () {
    final match = appRouter.configuration.findMatch(
      Uri.parse('${AppRoute.home}/recent/albums'),
    );
    expect(match.last.route.path, 'recent/albums');
    expect(
      [for (final r in match.routes.whereType<GoRoute>()) r.path],
      [AppRoute.home, 'recent/albums'],
    );
  });
}
