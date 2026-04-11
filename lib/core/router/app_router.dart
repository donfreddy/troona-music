import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/app_shell.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/utils/permission_handler.dart';
import 'package:troona/features/home/presentation/bloc/home_bloc.dart';
import 'package:troona/features/home/presentation/pages/home_page.dart';
import 'package:troona/features/library/presentation/bloc/album_detail/album_detail_bloc.dart';
import 'package:troona/features/library/presentation/bloc/artist_detail/artist_detail_bloc.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/library/presentation/pages/album_detail_page.dart';
import 'package:troona/features/library/presentation/pages/artist_detail_page.dart';
import 'package:troona/features/library/presentation/pages/library_page.dart';
import 'package:troona/features/playlist/presentation/bloc/playlist/playlist_bloc.dart';
import 'package:troona/features/playlist/presentation/bloc/playlist_detail/playlist_detail_bloc.dart';
import 'package:troona/features/playlist/presentation/widgets/playlist_detail_page.dart';
import 'package:troona/features/playlist/presentation/pages/playlist_page.dart';
import 'package:troona/features/search/presentation/bloc/search_bloc.dart';
import 'package:troona/features/search/presentation/pages/search_page.dart';
import 'package:troona/features/permissions/presentation/pages/permission_page.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/pages/full_player_page.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/features/settings/presentation/pages/settings_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

abstract class AppRoute {
  static const home = '/home';
  static const library = '/library';
  static const search = '/search';
  static const playlists = '/playlists';
  static const player = '/player';
  static const permission = '/permission';
  static const settings = '/settings';

  static const albumDetail = 'album_detail';
  static const artistDetail = 'artist_detail';
  static const playlistDetail = 'playlist_detail';
}

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoute.home,
  redirect: (BuildContext context, GoRouterState state) async {
    if (state.matchedLocation == AppRoute.permission) return null;
    final hasPermission = await AppPermissionHandler.hasAudioPermission();
    return hasPermission ? null : AppRoute.permission;
  },
  routes: [
    // ── STATEFUL SHELL ROUTE ────────────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<PlayerBloc>.value(value: getIt<PlayerBloc>()),
            BlocProvider<LibraryBloc>(create: (_) => getIt<LibraryBloc>()),
          ],
          child: AppShell(
            navigationShell: navigationShell,
            location: state.matchedLocation,
          ),
        );
      },
      branches: [
        // Branch: Home
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', redirect: (_, _) => AppRoute.home),
            GoRoute(
              path: AppRoute.home,
              builder: (context, _) => BlocProvider(
                create: (_) => getIt<HomeBloc>()..add(HomeRefreshRequested()),
                child: const HomePage(),
              ),
            ),
          ],
        ),
        // Branch: Library
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.library,
              builder: (_, _) => LibraryPage(),
              routes: [
                GoRoute(
                  path: 'albums/:id',
                  name: AppRoute.albumDetail,
                  builder: (context, state) {
                    final id = int.parse(state.pathParameters['id']!);
                    return BlocProvider(
                      create: (_) =>
                          getIt<AlbumDetailBloc>()
                            ..add(AlbumDetailRequested(id)),
                      child: AlbumDetailPage(id: id.toString()),
                    );
                  },
                ),
                GoRoute(
                  path: 'artists/:id',
                  name: AppRoute.artistDetail,
                  builder: (context, state) {
                    final id = int.parse(state.pathParameters['id']!);
                    return BlocProvider(
                      create: (_) =>
                          getIt<ArtistDetailBloc>()
                            ..add(ArtistDetailRequested(id)),
                      child: ArtistDetailPage(id: id.toString()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        // Branch: Search
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.search,
              builder: (context, _) => BlocProvider(
                create: (_) => getIt<SearchBloc>(),
                child: const SearchPage(),
              ),
            ),
          ],
        ),
        // Branch: Playlists
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.playlists,
              builder: (context, _) => BlocProvider(
                create: (_) =>
                    getIt<PlaylistBloc>()..add(PlaylistListRequested()),
                child: const PlaylistPage(),
              ),
              routes: [
                GoRoute(
                  path: ':id',
                  name: AppRoute.playlistDetail,
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return BlocProvider(
                      create: (_) =>
                          getIt<PlaylistDetailBloc>()
                            ..add(PlaylistDetailRequested(id)),
                      child: PlaylistDetailPage(id: id),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── Utility Routes ──────────────────────────────────────────────────────
    GoRoute(
      path: AppRoute.settings,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, _) => BlocProvider(
        create: (_) => getIt<SettingsCubit>()..load(),
        child: const SettingsPage(),
      ),
    ),
    GoRoute(
      path: AppRoute.permission,
      builder: (_, _) => const PermissionPage(),
    ),
    GoRoute(
      path: AppRoute.player,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        fullscreenDialog: true,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        child: BlocProvider<PlayerBloc>.value(
          value: getIt<PlayerBloc>(),
          child: const FullPlayerPage(),
        ),
      ),
    ),
  ],
);
