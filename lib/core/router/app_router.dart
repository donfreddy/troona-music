import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/app_shell.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/utils/permission_handler.dart';
import 'package:troona/features/backup/presentation/cubit/backup_cubit.dart';
import 'package:troona/features/history/presentation/cubit/weekly_recap_cubit.dart';
import 'package:troona/features/history/presentation/pages/weekly_recap_page.dart';
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
import 'package:troona/features/settings/presentation/cubit/maintenance_cubit.dart';
import 'package:troona/features/settings/presentation/pages/privacy_page.dart';
import 'package:troona/features/settings/presentation/pages/settings_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

abstract class AppRoute {
  static const home = '/home';
  static const library = '/library';
  static const search = '/search';
  static const playlists = '/playlists';
  static const player = '/player';
  static const permission = '/permission';
  static const settings = 'settings';
  static const privacy = 'privacy';
  static const weeklyRecap = 'recap';

  static const albumDetail = 'album_detail';
  static const artistDetail = 'artist_detail';
  static const playlistDetail = 'playlist_detail';
}

GoRoute _buildAlbumDetailRoute({String? name}) => GoRoute(
  path: 'albums/:id',
  name: name,
  builder: (context, state) {
    final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
    return BlocProvider(
      create: (_) => getIt<AlbumDetailBloc>()..add(AlbumDetailRequested(id)),
      child: AlbumDetailPage(id: id.toString()),
    );
  },
);

GoRoute _buildArtistDetailRoute({String? name}) => GoRoute(
  path: 'artists/:id',
  name: name,
  builder: (context, state) {
    final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
    return BlocProvider(
      create: (_) => getIt<ArtistDetailBloc>()..add(ArtistDetailRequested(id)),
      child: ArtistDetailPage(id: id.toString()),
    );
  },
);

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
              name: AppRoute.home,
              builder: (context, _) => MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) =>
                        getIt<HomeBloc>()..add(HomeRefreshRequested()),
                  ),
                  BlocProvider(
                    create: (_) => getIt<WeeklyRecapCubit>()..load(),
                  ),
                ],
                child: const HomePage(),
              ),
              routes: [
                GoRoute(
                  path: AppRoute.weeklyRecap,
                  name: AppRoute.weeklyRecap,
                  builder: (_, _) => BlocProvider(
                    create: (_) => getIt<WeeklyRecapCubit>()..load(),
                    child: const WeeklyRecapPage(),
                  ),
                ),
                GoRoute(
                  path: AppRoute.settings,
                  name: AppRoute.settings,
                  builder: (context, _) => MultiBlocProvider(
                    providers: [
                      BlocProvider.value(
                        value: getIt<SettingsCubit>()..retryIfFailed(),
                      ),
                      BlocProvider(
                        create: (_) => getIt<MaintenanceCubit>()..load(),
                      ),
                      BlocProvider(create: (_) => getIt<BackupCubit>()),
                    ],
                    child: const SettingsPage(),
                  ),
                  routes: [
                    GoRoute(
                      path: AppRoute.privacy,
                      name: AppRoute.privacy,
                      builder: (_, _) => const PrivacyPage(),
                    ),
                  ],
                ),
                _buildAlbumDetailRoute(),
                _buildArtistDetailRoute(),
              ],
            ),
          ],
        ),
        // Branch: Library
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.library,
              name: AppRoute.library,
              builder: (_, _) => const LibraryPage(),
              routes: [
                _buildAlbumDetailRoute(name: AppRoute.albumDetail),
                _buildArtistDetailRoute(name: AppRoute.artistDetail),
              ],
            ),
          ],
        ),
        // Branch: Search
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.search,
              name: AppRoute.search,
              builder: (context, _) => BlocProvider(
                create: (_) => getIt<SearchBloc>(),
                child: const SearchPage(),
              ),
              routes: [_buildAlbumDetailRoute(), _buildArtistDetailRoute()],
            ),
          ],
        ),
        // Branch: Playlists
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.playlists,
              name: AppRoute.playlists,
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
                _buildAlbumDetailRoute(),
                _buildArtistDetailRoute(),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── Utility Routes ──────────────────────────────────────────────────────
    GoRoute(
      path: AppRoute.permission,
      builder: (_, _) => const PermissionPage(),
    ),
    GoRoute(
      path: AppRoute.player,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        fullscreenDialog: true,
        // Room for the ring to mini player morph (reference: about 500 ms).
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        child: BlocProvider<PlayerBloc>.value(
          value: getIt<PlayerBloc>(),
          child: FullPlayerPage(
            morphFromMini: state.extra != FullPlayerPage.noMorph,
          ),
        ),
      ),
    ),
  ],
);

extension NavigationContextExt on BuildContext {
  void pushAlbum(String albumId) {
    final location = GoRouterState.of(this).matchedLocation;
    if (location.startsWith(AppRoute.home)) {
      push('${AppRoute.home}/albums/$albumId');
    } else if (location.startsWith(AppRoute.search)) {
      push('${AppRoute.search}/albums/$albumId');
    } else if (location.startsWith(AppRoute.playlists)) {
      push('${AppRoute.playlists}/albums/$albumId');
    } else {
      push('${AppRoute.library}/albums/$albumId');
    }
  }

  void pushArtist(String artistId) {
    final location = GoRouterState.of(this).matchedLocation;
    if (location.startsWith(AppRoute.home)) {
      push('${AppRoute.home}/artists/$artistId');
    } else if (location.startsWith(AppRoute.search)) {
      push('${AppRoute.search}/artists/$artistId');
    } else if (location.startsWith(AppRoute.playlists)) {
      push('${AppRoute.playlists}/artists/$artistId');
    } else {
      push('${AppRoute.library}/artists/$artistId');
    }
  }

  void pushPlaylist(String playlistId) {
    push('${AppRoute.playlists}/$playlistId');
  }
}
