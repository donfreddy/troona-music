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
}
