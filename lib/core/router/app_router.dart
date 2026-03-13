import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/app_shell.dart';
import 'package:troona/features/home/presentation/pages/home_page.dart';
// import 'package:troona/features/library/presentation/bloc/library_bloc.dart';
// import 'package:troona/features/player/presentation/bloc/player_bloc.dart';
// import 'package:troona/features/player/presentation/pages/full_player_page.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _shellNavigatorKey,
  initialLocation: '/home',
  routes: [
    // Shell : toutes les pages avec la bottom bar
    ShellRoute(
      builder: (context, state, child) => MultiBlocProvider(
        providers: [
          // BlocProvider.value(value: getIt<PlayerBloc>()),
          // BlocProvider.value(value: getIt<LibraryBloc>()),
        ],
        child: AppShell(child: child),
      ),
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomePage()),
        // GoRoute(path: '/queue', builder: (_, __) => const QueuePage()),
        // GoRoute(path: '/search', builder: (_, __) => const SearchPage()),
        // GoRoute(path: '/visualizer', builder: (_, __) => const VisualizerPage()),
      ],
    ),

    // FullPlayer : hors du shell (pas de bottom bar)
    // GoRoute(
    //   path: '/player',
    //   pageBuilder: (context, state) => CupertinoPage(
    //     fullscreenDialog: true,
    //     child: BlocProvider.value(value: getIt<PlayerBloc>(), child: const FullPlayerPage()),
    //   ),
    // ),
  ],
);
