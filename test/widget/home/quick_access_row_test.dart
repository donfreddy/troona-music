import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/home/presentation/widgets/quick_access_row.dart';
import 'package:troona/l10n/app_localizations.dart';

void main() {
  testWidgets('Recently added opens its page in Home, not the Library', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(
            body: QuickAccessRow(likesCount: 0, totalTracks: 3),
          ),
          routes: [
            GoRoute(path: 'recent', builder: (_, _) => const Text('recent')),
          ],
        ),
        GoRoute(path: '/library', builder: (_, _) => const Text('library')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.dark,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recently added'));
    await tester.pumpAndSettle();
    expect(find.text('recent'), findsOneWidget);
    expect(find.text('library'), findsNothing);
    // Pushed over Home: back returns to it.
    expect(router.canPop(), isTrue);
  });
}
