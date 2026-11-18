import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/router/app_router.dart';

/// A page with buttons that open albums and artists, as album and artist
/// pages, cards and links do.
class _Page extends StatelessWidget {
  final String label;
  const _Page(this.label);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text(label),
        for (final id in ['1', '2'])
          TextButton(
            onPressed: () => context.pushArtist(id),
            child: Text('open artist $id'),
          ),
        TextButton(
          onPressed: () => context.pushAlbum('7'),
          child: const Text('open album 7'),
        ),
      ],
    ),
  );
}

void main() {
  late GoRouter router;

  List<GoRoute> details() => [
    GoRoute(
      path: 'albums/:id',
      builder: (_, s) => _Page('album ${s.pathParameters['id']}'),
    ),
    GoRoute(
      path: 'artists/:id',
      builder: (_, s) => _Page('artist ${s.pathParameters['id']}'),
    ),
  ];

  Future<void> pump(WidgetTester tester, {String start = '/library'}) async {
    router = GoRouter(
      initialLocation: start,
      routes: [
        GoRoute(
          path: '/library',
          builder: (_, _) => const _Page('library'),
          routes: details(),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const _Page('home'),
          routes: details(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  }

  Future<void> tap(WidgetTester tester, String button) async {
    await tester.tap(find.text(button));
    await tester.pumpAndSettle();
  }

  String shown() => router.state.uri.path;

  testWidgets("an album's artist, opened from that artist, goes back to it", (
    tester,
  ) async {
    await pump(tester);
    await tap(tester, 'open artist 1');
    await tap(tester, 'open album 7');
    expect(shown(), '/library/albums/7');

    await tap(tester, 'open artist 1');
    expect(shown(), '/library/artists/1');
    expect(find.text('artist 1'), findsOneWidget);

    // Back once more reaches the library: no copies piled up.
    router.pop();
    await tester.pumpAndSettle();
    expect(shown(), '/library');
  });

  testWidgets('the album, opened again from its artist, goes back to it', (
    tester,
  ) async {
    await pump(tester);
    await tap(tester, 'open album 7');
    await tap(tester, 'open artist 1');
    await tap(tester, 'open album 7');
    expect(shown(), '/library/albums/7');
    router.pop();
    await tester.pumpAndSettle();
    expect(shown(), '/library');
  });

  testWidgets('another artist is pushed, in the same tab', (tester) async {
    await pump(tester, start: '/home');
    await tap(tester, 'open artist 1');
    await tap(tester, 'open album 7');
    await tap(tester, 'open artist 2');
    expect(shown(), '/home/artists/2');

    router.pop();
    await tester.pumpAndSettle();
    expect(shown(), '/home/albums/7');
  });

  group('from where no page names the tab (a sheet, Now Playing)', () {
    /// The tabs in a shell, as the app has them, and Now Playing over them.
    Future<void> pumpShell(WidgetTester tester) async {
      final root = GlobalKey<NavigatorState>();
      GoRoute tab(String path) => GoRoute(
        path: path,
        builder: (_, _) => _Page(path.substring(1)),
        routes: details(),
      );
      router = GoRouter(
        navigatorKey: root,
        initialLocation: AppRoute.library,
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => shell,
            branches: [
              StatefulShellBranch(routes: [tab(AppRoute.home)]),
              StatefulShellBranch(routes: [tab(AppRoute.library)]),
            ],
          ),
          GoRoute(
            path: AppRoute.player,
            parentNavigatorKey: root,
            builder: (_, _) => const Scaffold(body: Text('Now Playing')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    }

    testWidgets('the page opened knows the page it came from: going back to '
        'it does not pile up a copy', (tester) async {
      await pumpShell(tester);
      await tap(tester, 'open album 7');
      router.push(AppRoute.player);
      await tester.pumpAndSettle();

      // Go to artist from Now Playing: it closes, the artist opens.
      router.pop();
      pushDetailInTab(router, 'artists', '1');
      await tester.pumpAndSettle();
      expect(shown(), '/library/artists/1');
      expect(router.state.extra, '/library/albums/7');

      await tap(tester, 'open album 7');
      expect(shown(), '/library/albums/7');
      router.pop();
      await tester.pumpAndSettle();
      expect(shown(), '/library');
    });

    testWidgets('the page already shown stays as it is', (tester) async {
      await pumpShell(tester);
      await tap(tester, 'open album 7');
      router.push(AppRoute.player);
      await tester.pumpAndSettle();

      // Go to album from Now Playing, on the album below it.
      router.pop();
      pushDetailInTab(router, 'albums', '7');
      await tester.pumpAndSettle();
      expect(shown(), '/library/albums/7');
      router.pop();
      await tester.pumpAndSettle();
      expect(shown(), '/library', reason: 'one album page, not two');
    });

    testWidgets('the page it was opened from is gone back to', (tester) async {
      await pumpShell(tester);
      await tap(tester, 'open artist 1');
      await tap(tester, 'open album 7');
      router.push(AppRoute.player);
      await tester.pumpAndSettle();

      // Go to artist from Now Playing: the artist the album came from.
      router.pop();
      pushDetailInTab(router, 'artists', '1');
      await tester.pumpAndSettle();
      expect(shown(), '/library/artists/1');
      router.pop();
      await tester.pumpAndSettle();
      expect(shown(), '/library');
    });

    testWidgets('from a tab root, the root', (tester) async {
      await pumpShell(tester);
      pushDetailInTab(router, 'albums', '7');
      await tester.pumpAndSettle();
      expect(router.state.extra, '/library');
    });
  });
}
