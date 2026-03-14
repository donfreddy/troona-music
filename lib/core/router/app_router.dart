import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/app_shell.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/features/home/presentation/pages/home_page.dart';
import 'package:troona/features/library/presentation/bloc/library_bloc.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/pages/full_player_page.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Application router.
///
/// **BLoC lifecycle notes**:
/// - [PlayerBloc] is a **singleton** (registered via `get_it`). It must not be
///   closed by the widget tree, so it is provided with [BlocProvider.value].
/// - [LibraryBloc] is a **factory** that is owned and closed by the
///   [ShellRoute]'s [BlocProvider]. The initial scan is triggered in
///   [AppShell.initState] via `addPostFrameCallback`, not here, to keep
///   routing and business logic decoupled.
final appRouter = GoRouter(
  navigatorKey: _shellNavigatorKey,
  initialLocation: '/home',
  routes: [
    // ── Shell: all pages that share the bottom navigation bar ───────────────
    ShellRoute(
      builder: (context, state, child) => MultiBlocProvider(
        providers: [
          // PlayerBloc is a singleton — use .value so the provider never
          // calls close() on it when the shell is torn down.
          BlocProvider<PlayerBloc>.value(value: getIt<PlayerBloc>()),

          // LibraryBloc is a factory — the provider owns its lifecycle.
          // The initial scan is dispatched from AppShell.initState.
          BlocProvider<LibraryBloc>(create: (_) => getIt<LibraryBloc>()),
        ],
        child: AppShell(child: child),
      ),
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomePage()),
        GoRoute(
          path: '/queue',
          builder: (_, _) => const _StubPage(title: 'Queue'),
        ),
        GoRoute(
          path: '/search',
          builder: (_, _) => const _StubPage(title: 'Search'),
        ),
        GoRoute(
          path: '/visualizer',
          builder: (_, _) => const _StubPage(title: 'Now Playing'),
        ),
      ],
    ),

    // ── FullPlayer: fullscreen modal outside the shell (no bottom bar) ──────
    GoRoute(
      path: '/player',
      pageBuilder: (context, state) => CupertinoPage(
        fullscreenDialog: true,
        // Reuse the singleton — BlocProvider.value does not close the bloc.
        child: MultiBlocProvider(
          providers: [
            BlocProvider<PlayerBloc>.value(value: getIt<PlayerBloc>()),
            BlocProvider(
              create: (_) => LikesCubit(
                addTrack: getIt(),
                removeTrack: getIt(),
                isTrackLiked: getIt(),
              ),
            ),
          ],
          child: const FullPlayerPage(),
        ),
      ),
    ),
  ],
);

/// Placeholder widget for routes that are not yet implemented.
class _StubPage extends StatelessWidget {
  final String title;
  const _StubPage({required this.title});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Center(
      child: Text(
        '$title — coming soon',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    ),
  );
}
