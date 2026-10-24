import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/app_shell.dart';

/// A shell shaped like the app's: a home branch with a pushed detail page.
GoRouter _router() => GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => shell,
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) => const Text('home'),
              routes: [
                GoRoute(
                  name: 'album',
                  path: 'albums/:id',
                  builder: (_, state) =>
                      Text('album ${state.pathParameters['id']}'),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

void main() {
  late GoRouter router;
  late List<String?> seen;

  Future<void> pumpRouter(WidgetTester tester) async {
    router = _router();
    addTearDown(router.dispose);
    seen = [];
    router.routerDelegate.addListener(
      () => seen.add(AppShell.locationOf(router)),
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(AppShell.locationOf(router), '/home');
  }

  testWidgets('a pushed detail page is the current location', (tester) async {
    await pumpRouter(tester);

    router.pushNamed('album', pathParameters: {'id': '7'});
    await tester.pumpAndSettle();

    expect(find.text('album 7'), findsOneWidget);
    expect(seen.last, '/home/albums/7');
  });

  testWidgets('a system back from a detail page reports the root again', (
    tester,
  ) async {
    await pumpRouter(tester);
    router.pushNamed('album', pathParameters: {'id': '7'});
    await tester.pumpAndSettle();

    // Android back button / iOS swipe: goes through the delegate only.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(seen.last, '/home');
  });

  testWidgets('the back button of the page reports the root again', (
    tester,
  ) async {
    await pumpRouter(tester);
    router.pushNamed('album', pathParameters: {'id': '7'});
    await tester.pumpAndSettle();

    router.pop();
    await tester.pumpAndSettle();

    expect(seen.last, '/home');
  });
}
