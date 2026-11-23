import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/app_shell.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/utils/permission_handler.dart';
import 'package:troona/features/backup/presentation/cubit/backup_cubit.dart';
import 'package:troona/features/updates/presentation/cubit/update_cubit.dart';
import 'package:troona/features/history/presentation/cubit/listening_recap_cubit.dart';
import 'package:troona/features/history/presentation/pages/listening_recap_page.dart';
import 'package:troona/features/home/presentation/bloc/home_bloc.dart';
import 'package:troona/features/home/presentation/pages/home_page.dart';
import 'package:troona/features/library/presentation/bloc/album_detail/album_detail_bloc.dart';
import 'package:troona/features/library/presentation/bloc/artist_detail/artist_detail_bloc.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/library/presentation/pages/album_detail_page.dart';
import 'package:troona/features/library/presentation/pages/artist_detail_page.dart';
import 'package:troona/features/library/presentation/pages/artist_songs_page.dart';
import 'package:troona/features/library/presentation/pages/recent_albums_page.dart';
import 'package:troona/features/library/presentation/pages/recently_added_page.dart';
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
import 'package:troona/features/backup/presentation/pages/backup_page.dart';
import 'package:troona/features/settings/presentation/pages/about_page.dart';
import 'package:troona/features/settings/presentation/pages/appearance_settings_page.dart';
import 'package:troona/features/settings/presentation/pages/audio_settings_page.dart';
import 'package:troona/features/settings/presentation/pages/library_folders_page.dart';
import 'package:troona/features/settings/presentation/pages/licenses_page.dart';
import 'package:troona/features/settings/presentation/pages/library_settings_page.dart';
import 'package:troona/features/settings/presentation/pages/online_settings_page.dart';
import 'package:troona/features/settings/presentation/pages/privacy_page.dart';
import 'package:troona/features/settings/presentation/pages/storage_settings_page.dart';
import 'package:troona/features/settings/presentation/pages/settings_page.dart';
import 'package:troona/shared/widgets/ambient_background.dart';
import 'package:troona/shared/widgets/tab_reselect.dart';

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
  static const backup = 'backup';
  static const settingsAudio = 'settings_audio';
  static const settingsLibrary = 'settings_library';
  static const settingsOnline = 'settings_online';
  static const settingsAppearance = 'settings_appearance';
  static const settingsStorage = 'settings_storage';
  static const settingsAbout = 'settings_about';
  static const settingsFolders = 'settings_folders';
  static const settingsLicenses = 'settings_licenses';
  static const settingsLicense = 'settings_license';
  static const weeklyRecap = 'recap';

  static const albumDetail = 'album_detail';
  static const artistDetail = 'artist_detail';
  static const playlistDetail = 'playlist_detail';
}

/// A page pushed over a tab's root page. The tab pages are transparent over
/// the shell's [AmbientBackground]; a pushed page without a background of
/// its own gets a copy, or the page below would show through it while it
/// slides in. Album, artist and playlist pages paint their own.
Widget _overTab(Widget page) => AmbientBackground(child: page);

/// A page of Settings, with what its rows read and change: singletons, so
/// a change on one page shows on the others (a cache cleared, on the
/// root's row).
Widget _settingsPage(Widget page) => _overTab(
  MultiBlocProvider(
    providers: [
      BlocProvider.value(value: getIt<SettingsCubit>()),
      BlocProvider.value(value: getIt<MaintenanceCubit>()),
      BlocProvider.value(value: getIt<BackupCubit>()),
      BlocProvider.value(value: getIt<UpdateCubit>()),
    ],
    child: page,
  ),
);

GoRoute _settingsRoute(String name, Widget page) => GoRoute(
  path: name.replaceFirst('settings_', ''),
  name: name,
  builder: (_, _) => _settingsPage(page),
);

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

/// Every song of an artist (`artists/:id/songs`), beside their page rather
/// than under it: pushed, a nested route would bring a second copy of the
/// artist page along.
GoRoute _buildArtistSongsRoute() => GoRoute(
  path: 'artists/:id/songs',
  builder: (context, state) {
    final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
    return BlocProvider(
      create: (_) => getIt<ArtistDetailBloc>()..add(ArtistDetailRequested(id)),
      child: _overTab(ArtistSongsPage(id: id)),
    );
  },
);

/// The songs added last (`recent`), opened from Home's Recently added
/// chip and Search's suggestions, in their own tab.
GoRoute _buildRecentlyAddedRoute() => GoRoute(
  path: 'recent',
  builder: (_, _) => _overTab(const RecentlyAddedPage()),
);

/// The albums added last (`/home/recent/albums`), opened from Home's
/// Recently added row. A sibling of `recent`, not nested, or the pushed
/// page would bring the songs' page under it.
GoRoute _buildRecentAlbumsRoute() => GoRoute(
  path: 'recent/albums',
  builder: (_, _) => _overTab(const RecentAlbumsPage()),
);

/// go_router's indexed stack of tabs, with heroes off in the tabs not shown.
/// Their pages stay mounted, and a flight on the root navigator (the mini
/// player into Now Playing) gathers the heroes of every navigator: the same
/// album cover in two tabs would share a tag, and the flight would throw.
@visibleForTesting
Widget tabsContainer(
  BuildContext context,
  StatefulNavigationShell shell,
  List<Widget> children,
) => IndexedStack(
  index: shell.currentIndex,
  children: [
    for (final (i, child) in children.indexed)
      Offstage(
        offstage: i != shell.currentIndex,
        child: TickerMode(
          enabled: i == shell.currentIndex,
          child: HeroMode(enabled: i == shell.currentIndex, child: child),
        ),
      ),
  ],
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
    StatefulShellRoute(
      navigatorContainerBuilder: tabsContainer,
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
                    create: (_) => getIt<ListeningRecapCubit>()..load(),
                  ),
                ],
                child: const ScrollToTopOnReselect(
                  branch: 0,
                  child: HomePage(),
                ),
              ),
              routes: [
                GoRoute(
                  path: AppRoute.weeklyRecap,
                  name: AppRoute.weeklyRecap,
                  builder: (_, _) => _overTab(
                    BlocProvider(
                      create: (_) => getIt<ListeningRecapCubit>()..load(),
                      child: const ListeningRecapPage(),
                    ),
                  ),
                ),
                GoRoute(
                  path: AppRoute.settings,
                  name: AppRoute.settings,
                  builder: (context, _) => _overTab(
                    MultiBlocProvider(
                      providers: [
                        BlocProvider.value(
                          value: getIt<SettingsCubit>()..retryIfFailed(),
                        ),
                        BlocProvider.value(value: getIt<MaintenanceCubit>()),
                        BlocProvider.value(value: getIt<BackupCubit>()),
                        BlocProvider.value(value: getIt<UpdateCubit>()),
                      ],
                      child: const SettingsPage(),
                    ),
                  ),
                  routes: [
                    _settingsRoute(
                      AppRoute.settingsAudio,
                      const AudioSettingsPage(),
                    ),
                    _settingsRoute(
                      AppRoute.settingsLibrary,
                      const LibrarySettingsPage(),
                    ),
                    // Built on each visit: its repository is resolved
                    // when the page opens, not when the router is made.
                    GoRoute(
                      path: 'folders',
                      name: AppRoute.settingsFolders,
                      builder: (_, _) =>
                          _settingsPage(LibraryFoldersPage(stored: getIt())),
                    ),
                    _settingsRoute(
                      AppRoute.settingsOnline,
                      const OnlineSettingsPage(),
                    ),
                    _settingsRoute(
                      AppRoute.settingsAppearance,
                      const AppearanceSettingsPage(),
                    ),
                    _settingsRoute(
                      AppRoute.settingsStorage,
                      const StorageSettingsPage(),
                    ),
                    _settingsRoute(AppRoute.settingsAbout, const AboutPage()),
                    GoRoute(
                      path: 'licenses',
                      name: AppRoute.settingsLicenses,
                      builder: (_, _) => _overTab(const LicensesPage()),
                      routes: [
                        GoRoute(
                          path: ':index',
                          name: AppRoute.settingsLicense,
                          builder: (_, state) => _overTab(
                            LicenseDetailPage(
                              index:
                                  int.tryParse(
                                    state.pathParameters['index'] ?? '',
                                  ) ??
                                  -1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: AppRoute.privacy,
                      name: AppRoute.privacy,
                      builder: (_, _) => _overTab(const PrivacyPage()),
                    ),
                    GoRoute(
                      path: AppRoute.backup,
                      name: AppRoute.backup,
                      builder: (_, _) => _overTab(
                        MultiBlocProvider(
                          providers: [
                            BlocProvider.value(value: getIt<BackupCubit>()),
                            // A restore applies the backup's settings.
                            BlocProvider.value(value: getIt<SettingsCubit>()),
                          ],
                          child: const BackupPage(),
                        ),
                      ),
                    ),
                  ],
                ),
                _buildRecentlyAddedRoute(),
                _buildRecentAlbumsRoute(),
                _buildAlbumDetailRoute(),
                _buildArtistDetailRoute(),
                _buildArtistSongsRoute(),
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
              builder: (_, _) =>
                  const ScrollToTopOnReselect(branch: 1, child: LibraryPage()),
              routes: [
                _buildAlbumDetailRoute(name: AppRoute.albumDetail),
                _buildArtistDetailRoute(name: AppRoute.artistDetail),
                _buildArtistSongsRoute(),
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
                child: const ScrollToTopOnReselect(
                  branch: 2,
                  child: SearchPage(),
                ),
              ),
              routes: [
                _buildRecentlyAddedRoute(),
                _buildAlbumDetailRoute(),
                _buildArtistDetailRoute(),
                _buildArtistSongsRoute(),
              ],
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
                child: const ScrollToTopOnReselect(
                  branch: 3,
                  child: PlaylistPage(),
                ),
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
                _buildArtistSongsRoute(),
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
        // No fade of the whole page: it fades its own layers (background,
        // chrome, stage) while the heroes fly, so two screens never show
        // on top of each other.
        transitionsBuilder: (_, _, _, child) => child,
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

/// The tab a location belongs to, as its root path.
String tabOf(String location) => switch (location) {
  _ when location.startsWith(AppRoute.home) => AppRoute.home,
  _ when location.startsWith(AppRoute.search) => AppRoute.search,
  _ when location.startsWith(AppRoute.playlists) => AppRoute.playlists,
  _ => AppRoute.library,
};

/// Pushes an album or artist page ([section] `albums` or `artists`) in the
/// tab shown, from where no page context says which (a sheet, Now Playing
/// once closed), handing it the page shown as the one it was opened from.
/// The page already shown stays as it is, and the page it was opened from
/// is gone back to, as [NavigationContextExt.pushAlbum] does.
void pushDetailInTab(GoRouter router, String section, String id) {
  final (path: here, :extra) = shownPage(router);
  final target = '${tabOf(here)}/$section/$id';
  if (target == here) return;
  if (extra == target && router.canPop()) {
    router.pop();
    return;
  }
  router.push(target, extra: here);
}

/// The page shown in the tabs, Now Playing left out: its location and the
/// `extra` it was opened with. The router's own location keeps the last
/// `go` (a tab root): pages pushed since are matches of their own, the last
/// one on top, inside the tabs' shell for the pages of a tab.
@visibleForTesting
({String path, Object? extra}) shownPage(GoRouter router) {
  ({String path, Object? extra})? pushed(List<RouteMatchBase> matches) {
    for (final match in matches.reversed) {
      if (match is ShellRouteMatch) {
        final inside = pushed(match.matches);
        if (inside != null) return inside;
      } else if (match is ImperativeRouteMatch &&
          match.matches.uri.path != AppRoute.player) {
        return (path: match.matches.uri.path, extra: match.matches.extra);
      }
    }
    return null;
  }

  final config = router.routerDelegate.currentConfiguration;
  return pushed(config.matches) ?? (path: config.uri.path, extra: null);
}

extension NavigationContextExt on BuildContext {
  void pushAlbum(String albumId) => _pushDetail('albums', albumId);

  void pushArtist(String artistId) => _pushDetail('artists', artistId);

  /// Pushes the album or artist page within the current tab. When that page
  /// is the one this page was opened from (an album's artist, opened from
  /// the artist), goes back to it instead: artist, album, artist, album...
  /// would pile up copies, and back would walk through them all.
  ///
  /// The pushed page gets the location it was opened from as `extra`, a
  /// plain string: go_router encodes `extra` when it saves the route, and
  /// drops (with a warning) any type it cannot write as JSON.
  void _pushDetail(String section, String id) {
    final state = GoRouterState.of(this);
    final here = state.uri.path;
    final target = '${tabOf(here)}/$section/$id';
    if (state.extra case final String openedFrom
        when openedFrom == target && canPop()) {
      pop();
      return;
    }
    push(target, extra: here);
  }

  /// Pushes every song of an artist, in the current tab, handed the page
  /// it was opened from (their page): opening that artist again from the
  /// songs goes back to it instead of piling up a copy.
  void pushArtistSongs(String artistId) {
    final here = GoRouterState.of(this).uri.path;
    push('${tabOf(here)}/artists/$artistId/songs', extra: here);
  }

  /// Pushes the songs added last, in the current tab (Home or Search,
  /// the two that declare the route).
  void pushRecentlyAdded() =>
      push('${tabOf(GoRouterState.of(this).uri.path)}/recent');

  /// Pushes the albums added last, in Home, the only tab that opens them.
  void pushRecentAlbums() => push('${AppRoute.home}/recent/albums');

  void pushPlaylist(String playlistId) {
    push('${AppRoute.playlists}/$playlistId');
  }
}
