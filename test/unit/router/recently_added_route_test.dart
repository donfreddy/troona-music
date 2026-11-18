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
}
