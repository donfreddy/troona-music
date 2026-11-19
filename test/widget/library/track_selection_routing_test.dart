import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/presentation/bloc/selection/track_selection_cubit.dart';
import 'package:troona/features/library/presentation/widgets/selection/selection_place.dart';
import 'package:troona/features/library/presentation/widgets/selection/track_selection_scope.dart';
import 'package:troona/l10n/app_localizations.dart';

import '../../helpers/fake_player.dart';

/// The app's way back: a router, whose system back goes through the
/// scope's listener, and pages that keep their swipe back.
void main() {
  final songs = [
    for (final id in ['a', 'b']) testTrack(id, durationMs: 1000),
  ];

  late TrackSelectionCubit selection;
  late GoRouter router;

  Widget list() => Scaffold(
    body: TrackSelectionScope(
      tracks: songs,
      child: Builder(
        builder: (context) => ListView(
          children: [
            for (final song in songs)
              GestureDetector(
                onLongPress: () => TrackSelectionScope.longPress(context, song),
                child: SizedBox(height: 56, child: Text('Title ${song.id}')),
              ),
          ],
        ),
      ),
    ),
  );

  /// [router] shown, with [at] pushed if given, and song a picked.
  Future<void> start(WidgetTester tester, GoRouter router, [String? at]) async {
    // Resumed, as the app is: the platform hears about back handling only
    // then.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    selection = TrackSelectionCubit();
    addTearDown(selection.close);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      BlocProvider.value(
        value: selection,
        child: MaterialApp.router(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    if (at != null) router.push(at);
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Title a'));
    await tester.pumpAndSettle();
    expect(selection.state.active, isTrue);
  }

  /// What the app tells Android about back presses, in order: true while
  /// it takes them.
  List<Object?> listenBack(WidgetTester tester) {
    final handlesBack = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
          handlesBack.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    return handlesBack;
  }

  Future<void> pump(WidgetTester tester) async {
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('home')),
          routes: [GoRoute(path: 'list', builder: (_, _) => list())],
        ),
      ],
    );
    await start(tester, router, '/list');
  }

  testWidgets('the system back ends the selection first, then leaves', (
    tester,
  ) async {
    await pump(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(selection.state.active, isFalse);
    expect(find.text('Title a'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('over a sheet, the system back closes the sheet', (tester) async {
    await pump(tester);
    showModalBottomSheet<void>(
      context: tester.element(find.text('Title a')),
      useRootNavigator: true,
      builder: (_) => const SizedBox(height: 200, child: Text('sheet')),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsNothing);
    expect(selection.state.active, isTrue);
  });

  testWidgets('at the root, the app tells the system it takes the back '
      'press, and back ends the selection', (tester) async {
    final handlesBack = listenBack(tester);
    // A tab root: nothing below it to go back to. Without this, Android 16
    // leaves the app on back.
    await start(
      tester,
      GoRouter(
        initialLocation: '/list',
        routes: [GoRoute(path: '/list', builder: (_, _) => list())],
      ),
    );
    expect(handlesBack.last, isTrue);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(selection.state.active, isFalse);
    expect(handlesBack.last, isFalse);
  });

  testWidgets('at a tab root, a sheet over the shell closing leaves the app '
      'taking the back press', (tester) async {
    final handlesBack = listenBack(tester);
    final root = GlobalKey<NavigatorState>();
    await start(
      tester,
      GoRouter(
        navigatorKey: root,
        initialLocation: '/tab',
        routes: [
          StatefulShellRoute.indexedStack(
            // As AppShell: the shell's route cannot pop while picking.
            builder: (_, state, shell) =>
                SelectionPlace(place: state.uri.path, child: shell),
            branches: [
              StatefulShellBranch(
                routes: [GoRoute(path: '/tab', builder: (_, _) => list())],
              ),
            ],
          ),
        ],
      ),
    );
    expect(handlesBack.last, isTrue);

    // The root navigator speaks for its own routes once the sheet goes.
    showModalBottomSheet<void>(
      context: root.currentContext!,
      useRootNavigator: true,
      builder: (_) => const SizedBox(height: 100, child: Text('sheet')),
    );
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsNothing);
    expect(selection.state.active, isTrue);
    expect(handlesBack.last, isTrue);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(selection.state.active, isFalse);
    expect(handlesBack.last, isFalse);
  });

  testWidgets('a page over the shell (Now Playing) closes first', (
    tester,
  ) async {
    final root = GlobalKey<NavigatorState>();
    await start(
      tester,
      GoRouter(
        navigatorKey: root,
        initialLocation: '/tab',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => shell,
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/tab',
                    builder: (_, _) => const Scaffold(body: Text('tab')),
                    routes: [GoRoute(path: 'list', builder: (_, _) => list())],
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/player',
            parentNavigatorKey: root,
            builder: (_, _) => const Scaffold(body: Text('player')),
          ),
        ],
      ),
      '/tab/list',
    );
    GoRouter.of(tester.element(find.text('Title a'))).push('/player');
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('player'), findsNothing);
    expect(selection.state.active, isTrue);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(selection.state.active, isFalse);
    expect(find.text('Title a'), findsOneWidget);
  });

  testWidgets('a swipe back from the edge leaves the page, ending it', (
    tester,
  ) async {
    await pump(tester);
    final gesture = await tester.startGesture(const Offset(5, 300));
    for (var i = 0; i < 20; i++) {
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    expect(find.text('Title a'), findsNothing);
    expect(selection.state.active, isFalse);
  });
}
