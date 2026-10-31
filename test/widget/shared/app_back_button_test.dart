import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/app_back_button.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';

void main() {
  testWidgets('in an AppBar it stays a 45 dp circle, as far from the edge as '
      'on the detail pages, and goes back', (tester) async {
    final router = GoRouter(
      initialLocation: '/pushed',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('below')),
          routes: [
            GoRoute(
              path: 'pushed',
              builder: (_, _) => Scaffold(
                appBar: AppBar(
                  leadingWidth: AppBackButton.leadingWidth,
                  leading: const AppBackButton(),
                  title: const Text('Settings'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    final circle = tester.getRect(
      find.descendant(
        of: find.byType(GlassIconButton),
        matching: find.byType(Container),
      ),
    );
    expect(circle.size, const Size(45, 45));
    expect(circle.left, AppSpacing.sm);

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();
    expect(find.text('below'), findsOneWidget);
  });
}
