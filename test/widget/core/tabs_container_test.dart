import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/router/app_router.dart';

/// A tab showing the same cover as the other tab, as Home and Library may.
Widget _tab(String label) => Scaffold(
  body: Column(
    children: [
      Text(label),
      const Hero(tag: 'cover', child: SizedBox(width: 40, height: 40)),
    ],
  ),
);

void main() {
  testWidgets('a page pushed over the tabs flies with only the shown tab\'s '
      'heroes, though a hidden tab holds the same one', (tester) async {
    final rootKey = GlobalKey<NavigatorState>();
    late StatefulNavigationShell shell;
    final router = GoRouter(
      navigatorKey: rootKey,
      initialLocation: '/a',
      routes: [
        StatefulShellRoute(
          navigatorContainerBuilder: tabsContainer,
          builder: (_, _, s) => shell = s,
          branches: [
            StatefulShellBranch(
              routes: [GoRoute(path: '/a', builder: (_, _) => _tab('a'))],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: '/b', builder: (_, _) => _tab('b'))],
            ),
          ],
        ),
        GoRoute(
          path: '/player',
          parentNavigatorKey: rootKey,
          builder: (_, _) => const Scaffold(
            body: Hero(tag: 'cover', child: SizedBox(width: 300, height: 300)),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    // Both tabs mounted, b shown.
    shell.goBranch(1);
    await tester.pumpAndSettle();
    expect(find.text('a', skipOffstage: false), findsOneWidget);

    unawaited(router.push('/player'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    // The shown tab's cover is in flight: between its size and Now
    // Playing's.
    final sizes = [
      for (final box in find.byType(SizedBox).evaluate())
        (box.renderObject! as RenderBox).size.width,
    ];
    expect(sizes.any((w) => w > 40 && w < 300), isTrue, reason: '$sizes');
    await tester.pumpAndSettle();
    expect(find.byType(Hero), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
