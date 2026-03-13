import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/app_shell.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/features/home/presentation/pages/home_page.dart';
import 'package:troona/features/library/presentation/bloc/library_bloc.dart';
import 'package:troona/features/player/presentation/bloc/player_bloc.dart';
import 'package:troona/features/player/presentation/pages/full_player_page.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _shellNavigatorKey,
  initialLocation: '/home',
  routes: [
    // Shell : toutes les pages avec la bottom bar
    ShellRoute(
      builder: (context, state, child) => MultiBlocProvider(
        providers: [
          BlocProvider<PlayerBloc>(create: (_) => getIt<PlayerBloc>()),
          BlocProvider<LibraryBloc>(create: (_) => getIt<LibraryBloc>()..add(const LibraryScanRequested())),
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

    // FullPlayer : hors du shell (pas de bottom bar)
    GoRoute(
      path: '/player',
      pageBuilder: (context, state) => CupertinoPage(
        fullscreenDialog: true,
        child: BlocProvider.value(value: getIt<PlayerBloc>(), child: const FullPlayerPage()),
      ),
    ),
  ],
);

class _StubPage extends StatelessWidget {
  final String title;
  const _StubPage({required this.title});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Center(
      child: Text('$title page coming soon', style: const TextStyle(color: Colors.white, fontSize: 18)),
    ),
  );
}
