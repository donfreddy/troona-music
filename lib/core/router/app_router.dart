import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/app_shell.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/utils/permission_handler.dart';
import 'package:troona/features/home/presentation/pages/home_page.dart';
import 'package:troona/features/library/presentation/bloc/library_bloc.dart';
import 'package:troona/features/permissions/presentation/pages/permission_page.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/pages/full_player_page.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/features/settings/presentation/pages/settings_page.dart';

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

  /// Permission guard — fires before every navigation event.
  ///
  /// Skips the check when already on `/permission` to prevent an infinite
  /// redirect loop. All other routes require audio permission; if absent the
  /// user is sent to the onboarding gate.
  redirect: (BuildContext context, GoRouterState state) async {
    if (state.matchedLocation == '/permission') return null;
    final hasPermission = await AppPermissionHandler.hasAudioPermission();
    return hasPermission ? null : '/permission';
  },

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
          path: '/settings',
          builder: (context, _) => BlocProvider(
            create: (_) => getIt<SettingsCubit>()..load(),
            child: const SettingsPage(),
          ),
        ),
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

    // ── Permission gate: shown when audio/storage permission is missing ─────
    // Outside the shell — no bottom nav, no PlayerBloc overhead.
    GoRoute(
      path: '/permission',
      builder: (_, _) => const PermissionPage(),
    ),

    // ── FullPlayer: fullscreen modal outside the shell (no bottom bar) ──────
    //
    // Uses CustomTransitionPage with a bare fade instead of CupertinoPage's
    // built-in slide. The drag-to-dismiss gesture in FullPlayerPage drives the
    // visual translation manually; using a slide here would conflict and
    // produce a double-animation glitch. A short fade lets the Hero animation
    // (artwork expanding/contracting) be the primary visual transition —
    // matching the Apple Music approach.
    GoRoute(
      path: '/player',
      pageBuilder: (context, state) => CustomTransitionPage(
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            ),
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
