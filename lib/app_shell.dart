import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/permission_handler.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/pages/full_player_page.dart';
import 'package:troona/shared/widgets/app_bottom_nav_bar.dart';
import 'package:troona/shared/widgets/dynamic_background.dart';
import 'package:troona/shared/widgets/error_view.dart';
import 'package:troona/services/scanner/media_scanner_service.dart';

class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final String location;

  const AppShell({
    super.key,
    required this.navigationShell,
    required this.location,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _didRequestPlaybackRestore = false;
  bool _didRestoreFullPlayerRoute = false;
  String _currentLocation = '';
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.location;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _router = GoRouter.of(context);
      _router!.routeInformationProvider.addListener(_onRouteChanged);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final hasPermission = await AppPermissionHandler.hasAudioPermission();
      if (!mounted || !hasPermission) return;
      context.read<LibraryBloc>().add(const LibraryBootstrapRequested());
    });
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.location != oldWidget.location) {
      _currentLocation = widget.location;
    }
  }

  void _onRouteChanged() {
    if (!mounted) return;
    final newLocation = _router!.routeInformationProvider.value.uri.path;
    if (newLocation != _currentLocation) {
      setState(() => _currentLocation = newLocation);
    }
  }

  @override
  void dispose() {
    _router?.routeInformationProvider.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onTabChanged(AppTab tab) {
    if (tab == AppTab.player) return;

    final index = switch (tab) {
      AppTab.home => 0,
      AppTab.library => 1,
      AppTab.search => 2,
      AppTab.playlists => 3,
      _ => 0,
    };

    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final safeBottom = mediaQuery.padding.bottom;
    final safeTop = mediaQuery.padding.top;

    return MultiBlocListener(
      listeners: [
        BlocListener<LibraryBloc, LibraryState>(
          listenWhen: (previous, current) =>
              !_didRequestPlaybackRestore && _canRestorePlayback(current),
          listener: (context, state) {
            _didRequestPlaybackRestore = true;
            context.read<PlayerBloc>().add(
              const RestorePlaybackSessionRequested(),
            );
          },
        ),
        BlocListener<PlayerBloc, PlayerState>(
          listenWhen: (previous, current) =>
              !_didRestoreFullPlayerRoute &&
              getIt<PlaybackSessionStore>().wasFullPlayerOpen &&
              (current is PlayerLoading || current is PlayerActive),
          listener: (context, state) {
            _didRestoreFullPlayerRoute = true;
            if (GoRouterState.of(context).matchedLocation !=
                FullPlayerPage.routeName) {
              context.push(FullPlayerPage.routeName);
            }
          },
        ),
        BlocListener<PlayerBloc, PlayerState>(
          listener: (context, state) {
            final track = switch (state) {
              PlayerActive(:final currentTrack) => currentTrack,
              PlayerLoading(:final track) => track,
              _ => null,
            };
            context.read<TrackPaletteCubit>().updateTrack(track);
          },
        ),
      ],
      child: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, libraryState) {
          if (_shouldShowBootstrap(libraryState)) {
            return _LibraryBootstrapScreen(
              state: libraryState,
              onRetry: () =>
                  context.read<LibraryBloc>().add(const LibraryScanRequested()),
            );
          }

          final currentTab = _tabForIndex(widget.navigationShell.currentIndex);

          // Use the live _currentLocation which is updated via both
          // the widget prop and the GoRouter listener, ensuring we
          // always know the actual route — even after popping.
          final isRootPage = [
            AppRoute.home,
            AppRoute.library,
            AppRoute.search,
            AppRoute.playlists,
          ].contains(_currentLocation);

          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Positioned.fill(
                  child: BlocSelector<PlayerBloc, PlayerState, String?>(
                    selector: (s) => switch (s) {
                      PlayerActive(:final currentTrack) =>
                        currentTrack.artworkPath,
                      PlayerLoading(:final track) => track.artworkPath,
                      _ => null,
                    },
                    builder: (_, artworkPath) => DynamicBackground(
                      artworkPath: artworkPath,
                      tone: DynamicBackgroundTone.ambient,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),

                // ── The Branch Content ─────────────────────────────────────────
                Positioned.fill(child: widget.navigationShell),

                if (libraryState case LibraryScanning(
                  :final cached,
                ) when cached != null)
                  Positioned(
                    top: safeTop + 12,
                    left: 12,
                    right: 12,
                    child: _LibraryRescanBanner(state: libraryState),
                  ),

                // ── Bottom Bar ────────────────────────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, 0, 12, safeBottom + 12),
                    child: AppBottomNavBar(
                      currentTab: currentTab,
                      onTabChanged: _onTabChanged,
                      showTabs: isRootPage,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _shouldShowBootstrap(LibraryState state) => switch (state) {
    LibraryInitial() => true,
    LibraryScanning(:final cached) => cached == null,
    LibraryError(:final lastLoaded) => lastLoaded == null,
    _ => false,
  };

  bool _canRestorePlayback(LibraryState state) => switch (state) {
    LibraryLoaded() => true,
    LibraryScanning(:final cached) => cached != null,
    LibraryError(:final lastLoaded) => lastLoaded != null,
    _ => false,
  };

  AppTab _tabForIndex(int index) => switch (index) {
    0 => AppTab.home,
    1 => AppTab.library,
    2 => AppTab.search,
    3 => AppTab.playlists,
    _ => AppTab.home,
  };
}

// Keep the private bootstrap/banner classes below...
// (I am keeping them identical to your previous version but ensuring they are in the file)

class _LibraryBootstrapScreen extends StatelessWidget {
  final LibraryState state;
  final VoidCallback onRetry;

  const _LibraryBootstrapScreen({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.black,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.accent.withValues(alpha: .22),
              const Color(0xFF121212),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl2),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .10),
                    ),
                  ),
                  child: switch (state) {
                    LibraryError(:final message) => ErrorView(
                      message: message,
                      onRetry: onRetry,
                    ),
                    _ => _LibraryBootstrapContent(state: state),
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryBootstrapContent extends StatelessWidget {
  final LibraryState state;

  const _LibraryBootstrapContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scanning = state is LibraryScanning ? state as LibraryScanning : null;
    final progress = scanning?.progress.progress.clamp(0.0, 1.0);
    final showDeterminate =
        scanning != null &&
        scanning.progress.total > 0 &&
        scanning.progress.phase != ScanPhase.scanning;
    final counterLabel = scanning == null
        ? null
        : switch (scanning.progress.phase) {
            ScanPhase.scanning when scanning.progress.count > 0 =>
              '${scanning.progress.count} songs found',
            ScanPhase.indexing || ScanPhase.artworks
                when scanning.progress.total > 0 =>
              '${scanning.progress.count}/${scanning.progress.total}',
            _ => null,
          };
    final phaseLabel = switch (scanning?.progress.phase) {
      ScanPhase.scanning => 'Scanning your device for songs...',
      ScanPhase.indexing => 'Indexing your library...',
      ScanPhase.artworks => 'Loading album artwork...',
      ScanPhase.done => 'Preparing your home screen...',
      null => 'Preparing your home screen...',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.accent.withValues(alpha: .14),
            border: Border.all(color: colors.accent.withValues(alpha: .22)),
          ),
          child: const Icon(
            CupertinoIcons.music_note_list,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text(
          'Loading your music',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          phaseLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.labelSecondary,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        if (counterLabel != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            counterLabel,
            style: TextStyle(
              color: colors.labelTertiary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl2),
        if (showDeterminate)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: .10),
              valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
            ),
          )
        else
          const CupertinoActivityIndicator(radius: 14),
      ],
    );
  }
}

class _LibraryRescanBanner extends StatelessWidget {
  final LibraryScanning state;

  const _LibraryRescanBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progress = state.progress.progress.clamp(0.0, 1.0);
    final showDeterminate =
        state.progress.total > 0 && state.progress.phase != ScanPhase.scanning;
    final phaseLabel = switch (state.progress.phase) {
      ScanPhase.scanning => 'Scanning for new songs...',
      ScanPhase.indexing => 'Updating your library...',
      ScanPhase.artworks => 'Refreshing album artwork...',
      ScanPhase.done => 'Finalizing...',
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .58),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Updating your library',
              style: TextStyle(
                color: colors.labelPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              phaseLabel,
              style: TextStyle(color: colors.labelSecondary, fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (showDeterminate)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: .10),
                  valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                ),
              )
            else
              const CupertinoActivityIndicator(radius: 9),
          ],
        ),
      ),
    );
  }
}
