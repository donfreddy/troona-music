import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/permission_handler.dart';
import 'package:troona/features/library/presentation/bloc/library_bloc.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/pages/full_player_page.dart';
import 'package:troona/services/scanner/media_scanner_service.dart';
import 'package:troona/shared/widgets/error_view.dart';
import 'package:troona/shared/widgets/app_bottom_nav_bar.dart';

/// Root scaffold for all shell routes (routes that share the bottom nav bar).
///
/// The [AppBottomNavBar] is positioned at the bottom and internally manages
/// both the mini player row (when a track is active) and the nav tabs — as a
/// single unified glass container.
///
/// The initial library scan is dispatched here in [State.initState] via
/// `addPostFrameCallback`. This keeps `app_router.dart` free of
/// business-logic triggers.
class AppShell extends StatefulWidget {
  /// The currently active page injected by GoRouter's [ShellRoute].
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _didRequestPlaybackRestore = false;
  bool _didRestoreFullPlayerRoute = false;

  @override
  void initState() {
    super.initState();
    // Dispatch the scan after the first frame so that BlocProvider ancestors
    // are fully wired before context.read is called.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final hasPermission = await AppPermissionHandler.hasAudioPermission();
      if (!mounted || !hasPermission) return;
      context.read<LibraryBloc>().add(const LibraryBootstrapRequested());
    });
  }

  void _onTabChanged(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        context.go('/home');
      case AppTab.queue:
        context.go('/queue');
      case AppTab.search:
        context.go('/search');
      case AppTab.visualizer:
        context.go('/visualizer');
      case AppTab.player:
        break; // handled by the centre artwork slot in AppBottomNavBar
    }
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
            context.read<PlayerBloc>().add(const RestorePlaybackSessionRequested());
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

          final currentTab = _tabForLocation(
            GoRouterState.of(context).matchedLocation,
          );

          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                // ── Active page ───────────────────────────────────────────────
                Positioned.fill(child: widget.child),

                if (libraryState case LibraryScanning(
                  :final cached,
                ) when cached != null)
                  Positioned(
                    top: safeTop + 12,
                    left: 12,
                    right: 12,
                    child: _LibraryRescanBanner(state: libraryState),
                  ),

                // ── Unified bottom bar (mini player + nav tabs) ─────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, 0, 12, safeBottom + 12),
                    child: AppBottomNavBar(
                      currentTab: currentTab,
                      onTabChanged: _onTabChanged,
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

  AppTab _tabForLocation(String location) {
    if (location == '/queue') return AppTab.queue;
    if (location == '/search') return AppTab.search;
    if (location == '/visualizer') return AppTab.visualizer;
    return AppTab.home;
  }
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
