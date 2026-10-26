import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/extensions/context_ext.dart';
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
import 'package:troona/shared/widgets/app_toast.dart';
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

  /// Location of the page on top, pushed routes included (the
  /// configuration's uri does not change on push).
  static String? locationOf(GoRouter router) {
    final delegate = router.routerDelegate;
    if (delegate.currentConfiguration.isEmpty) return null;
    return delegate.state.matchedLocation;
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _didRequestPlaybackRestore = false;
  bool _didRestoreFullPlayerRoute = false;
  String _currentLocation = '';
  GoRouter? _router;
  StreamSubscription<PlayerNotice>? _noticesSub;
  LibraryLoaded? _rescanBaseline;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.location;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _router = GoRouter.of(context);
      // The delegate, not routeInformationProvider: a system back (Android
      // button, iOS swipe) pops through the delegate without notifying the
      // provider, and the tabs stayed hidden after leaving a detail page.
      _router!.routerDelegate.addListener(_onRouteChanged);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final hasPermission = await AppPermissionHandler.hasAudioPermission();
      if (!mounted || !hasPermission) return;
      context.read<LibraryBloc>().add(const LibraryBootstrapRequested());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _noticesSub = context.read<PlayerBloc>().notices.listen((notice) {
        if (!mounted) return;
        final l10n = context.l10n;
        final message = switch (notice) {
          TrackUnplayable(:final title?) => l10n.playerCantPlay(title),
          TrackUnplayable() => l10n.playerCantPlayUnknown,
        };
        AppToast.show(context, message);
      });
    });
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.location != oldWidget.location) {
      // The prop is the shell's base location, without pushed pages: once
      // the router is known, the delegate's top page wins (a branch can be
      // restored with a detail page on top).
      final router = _router;
      final top = router == null ? null : AppShell.locationOf(router);
      _currentLocation = top == null || top == FullPlayerPage.routeName
          ? widget.location
          : top;
    }
  }

  void _onRouteChanged() {
    if (!mounted) return;
    final newLocation = AppShell.locationOf(_router!);
    if (newLocation == null) return;
    // The full player covers the shell: keep the bar as it was, so the mini
    // player does not jump down (tabs hidden) under the finger as it morphs.
    if (newLocation == FullPlayerPage.routeName) return;
    if (newLocation != _currentLocation) {
      setState(() => _currentLocation = newLocation);
    }
  }

  @override
  void dispose() {
    _noticesSub?.cancel();
    _router?.routerDelegate.removeListener(_onRouteChanged);
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

    return MultiBlocListener(
      listeners: [
        BlocListener<LibraryBloc, LibraryState>(
          // A rescan over cached data runs silently; only its outcome is
          // worth a toast. listener only sees the new state, so the
          // baseline is captured here.
          listenWhen: (previous, current) {
            if (previous case LibraryScanning(
              :final cached?,
            ) when current is LibraryLoaded) {
              _rescanBaseline = cached;
              return true;
            }
            return false;
          },
          listener: (context, state) {
            final before = _rescanBaseline;
            _rescanBaseline = null;
            if (before != null && state is LibraryLoaded) {
              _announceRescan(before, state);
            }
          },
        ),
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
              // The mini player is still expanding from zero height here.
              context.push(
                FullPlayerPage.routeName,
                extra: FullPlayerPage.noMorph,
              );
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

          // _currentLocation follows both the widget prop and the router
          // delegate, so it is right after any pop, system back included.
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
                  child: BlocBuilder<TrackPaletteCubit, TrackPaletteState>(
                    builder: (_, palette) => DynamicBackground(
                      colorA: palette.backgroundColorA,
                      colorB: palette.backgroundColorB,
                      tone: DynamicBackgroundTone.ambient,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),

                // ── The Branch Content ─────────────────────────────────────────
                Positioned.fill(child: widget.navigationShell),

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

  void _announceRescan(LibraryLoaded before, LibraryLoaded after) {
    final beforeIds = {for (final t in before.allTracks) t.id};
    final afterIds = {for (final t in after.allTracks) t.id};
    final added = afterIds.difference(beforeIds).length;
    final removed = beforeIds.difference(afterIds).length;
    final l10n = context.l10n;
    if (added > 0) {
      AppToast.show(context, l10n.scanNewSongs(added));
    } else if (removed > 0) {
      AppToast.show(context, l10n.scanRemovedSongs(removed));
    }
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
                    LibraryError() => ErrorView(
                      title: context.l10n.libraryLoadErrorTitle,
                      body: context.l10n.libraryLoadErrorBody,
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
    final l10n = context.l10n;
    final counterLabel = scanning == null
        ? null
        : switch (scanning.progress.phase) {
            ScanPhase.scanning when scanning.progress.count > 0 =>
              l10n.scanSongsFound(scanning.progress.count),
            ScanPhase.indexing || ScanPhase.artworks
                when scanning.progress.total > 0 =>
              l10n.scanProgress(
                scanning.progress.count,
                scanning.progress.total,
              ),
            _ => null,
          };
    final phaseLabel = switch (scanning?.progress.phase) {
      ScanPhase.scanning => l10n.scanPhaseScanning,
      ScanPhase.indexing => l10n.scanPhaseIndexing,
      ScanPhase.artworks => l10n.scanPhaseArtwork,
      ScanPhase.done || null => l10n.scanPhaseDone,
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
        Text(
          l10n.scanTitle,
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
