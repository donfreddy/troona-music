import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/backup/domain/entities/stored_backup.dart';
import 'package:troona/features/backup/domain/use_cases/run_auto_backup_use_case.dart';
import 'package:troona/features/backup/presentation/cubit/backup_cubit.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/app_logger.dart';
import 'package:troona/core/utils/permission_handler.dart';
import 'package:troona/features/history/domain/use_cases/create_monthly_replay_use_case.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/library/presentation/bloc/selection/track_selection_cubit.dart';
import 'package:troona/features/library/presentation/widgets/selection/selection_actions.dart';
import 'package:troona/features/library/presentation/widgets/selection/selection_place.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/utils/orb_action.dart';
import 'package:troona/features/player/presentation/utils/open_full_player.dart';
import 'package:troona/features/home/presentation/widgets/quick_access_row.dart';
import 'package:troona/features/player/presentation/pages/full_player_page.dart';
import 'package:troona/features/player/presentation/widgets/now_playing_hero.dart';
import 'package:troona/features/player/domain/entities/opened_audio.dart';
import 'package:troona/features/player/domain/ports/opened_file_port.dart';
import 'package:troona/features/player/domain/use_cases/resolve_opened_file_use_case.dart';
import 'package:troona/features/player/presentation/utils/opened_file_handler.dart';
import 'package:troona/features/player/presentation/utils/play_opened_file.dart';
import 'package:troona/features/player/presentation/widgets/player_notice_toast.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/features/updates/presentation/cubit/update_cubit.dart';
import 'package:troona/features/whats_new/domain/use_cases/check_whats_new_use_case.dart';
import 'package:troona/features/whats_new/presentation/release_notes.dart';
import 'package:troona/features/whats_new/presentation/widgets/whats_new_sheet.dart';
import 'package:troona/shared/widgets/app_bottom_nav_bar.dart';
import 'package:troona/shared/widgets/app_toast.dart';
import 'package:troona/shared/widgets/ambient_background.dart';
import 'package:troona/shared/widgets/error_view.dart';
import 'package:troona/shared/widgets/tab_reselect.dart';
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
  final _reselect = TabReselectController();
  OpenedFileHandler? _opened;

  /// Checks for a due automatic backup on each return to the app.
  late final AppLifecycleListener _lifecycle;
  Timer? _firstAutoBackup;

  /// Said once per run: an automatic backup that cannot reach its folder.
  bool _toldBackupFolderLost = false;

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
      final player = context.read<PlayerBloc>();
      _noticesSub = player.notices.listen((notice) {
        if (!mounted) return;
        showPlayerNotice(
          context,
          notice,
          onUndo: () => player.add(const QueueReplaceUndone()),
        );
      });
    });
    // After the router is known (an earlier callback): Now Playing is
    // pushed through it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _opened = OpenedFileHandler(
        port: getIt<OpenedFilePort>(),
        resolve: getIt<ResolveOpenedFileUseCase>().call,
        onOpened: _onFileOpened,
      )..start();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _createMonthlyReplay());
    WidgetsBinding.instance.addPostFrameCallback((_) => _showWhatsNew());
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
    _lifecycle = AppLifecycleListener(onResume: _autoBackup);
    // A moment after start: the first frames and the library come first.
    _firstAutoBackup = Timer(const Duration(seconds: 5), _autoBackup);
  }

  /// The automatic backup, when it is on and due. Silent unless its folder
  /// can no longer be reached: the user would believe backups are made.
  Future<void> _autoBackup() async {
    final AutoBackupOutcome? outcome;
    try {
      outcome = await getIt<BackupCubit>().autoBackupIfDue();
    } catch (e, st) {
      appLogger.w('Automatic backup failed', error: e, stackTrace: st);
      return;
    }
    if (!mounted) return;
    switch (outcome) {
      case AutoBackupNoFolder(folder: BackupFolderLost()) ||
              AutoBackupFailed(failure: BackupFolderLostFailure())
          when !_toldBackupFolderLost:
        _toldBackupFolderLost = true;
        AppToast.show(context, context.l10n.backupAutoFolderLost);
      case AutoBackupFailed(:final failure):
        appLogger.w('Automatic backup not written: $failure');
      default:
        break;
    }
  }

  /// A file opened from another app ("Open with"), see [playOpenedFile].
  void _onFileOpened(OpenedAudio opened) {
    if (!mounted) return;
    final router = _router;
    playOpenedFile(
      opened,
      player: context.read<PlayerBloc>(),
      nowPlayingOnTop:
          router != null &&
          AppShell.locationOf(router) == FullPlayerPage.routeName,
      skipRestore: () {
        _didRequestPlaybackRestore = true;
        _didRestoreFullPlayerRoute = true;
      },
      // No morph: the mini player may not be up yet.
      showNowPlaying: () => unawaited(
        router?.push(FullPlayerPage.routeName, extra: FullPlayerPage.noMorph),
      ),
      sayNotInLibrary: () =>
          AppToast.show(context, context.l10n.openedFileNotInLibrary),
    );
  }

  /// "What's new", once after an update that ships notes.
  Future<void> _showWhatsNew() async {
    if (!mounted) return;
    final l10n = context.l10n;
    final String? version;
    try {
      version = await getIt<CheckWhatsNewUseCase>()(
        hasNotes: (v) => releaseNotes(l10n).any((r) => r.version == v),
      );
    } catch (e, st) {
      appLogger.w('What\'s new check failed', error: e, stackTrace: st);
      return;
    }
    if (version == null || !mounted) return;
    await showWhatsNewSheet(
      context,
      releases: releaseNotes(l10n),
      version: version,
    );
  }

  /// The daily update check, when it is on. Silent: Home shows a card.
  Future<void> _checkForUpdate() async {
    try {
      await getIt<UpdateCubit>().checkIfEnabled();
    } catch (e, st) {
      appLogger.w('Update check failed', error: e, stackTrace: st);
    }
  }

  /// Last month's Replay playlist, made once on the first run of a month.
  Future<void> _createMonthlyReplay() async {
    if (!mounted) return;
    final l10n = context.l10n;
    final monthName = DateFormat.yMMMM(
      Localizations.localeOf(context).toString(),
    );
    final result = await getIt<CreateMonthlyReplayUseCase>()(
      now: DateTime.now(),
      name: (month) => l10n.replayName(monthName.format(month)),
    );
    if (!mounted) return;
    result.fold(
      (failure) => appLogger.w('Monthly Replay not created: $failure'),
      (playlist) {
        if (playlist != null) {
          AppToast.show(context, l10n.replayReady(playlist.name));
        }
      },
    );
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
    _lifecycle.dispose();
    _firstAutoBackup?.cancel();
    _noticesSub?.cancel();
    unawaited(_opened?.dispose());
    _router?.routerDelegate.removeListener(_onRouteChanged);
    _reselect.dispose();
    super.dispose();
  }

  /// The orb at the centre of the bar: Now Playing while a song is loaded,
  /// music otherwise ([OrbAction]).
  void _onOrbTapped() {
    final player = context.read<PlayerBloc>();
    final action = OrbAction.of(
      player.state,
      hasSession: getIt<PlaybackSessionStore>().load() != null,
    );
    switch (action) {
      case OrbAction.openNowPlaying:
        openFullPlayer(context);
      case OrbAction.resumeSession:
        player.add(const RestorePlaybackSessionRequested(play: true));
      case OrbAction.shuffleLibrary:
        shuffleWholeLibrary(context);
    }
  }

  void _onTabChanged(AppTab tab) {
    if (tab == AppTab.player) {
      _onOrbTapped();
      return;
    }

    final index = switch (tab) {
      AppTab.home => 0,
      AppTab.library => 1,
      AppTab.search => 2,
      AppTab.playlists => 3,
      _ => 0,
    };

    final current = widget.navigationShell.currentIndex;
    // The tab shown, tapped again: its page goes back to the top (iOS).
    if (index == current && _isRootPage) _reselect.reselect(index);

    widget.navigationShell.goBranch(index, initialLocation: index == current);
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
            if (previous case LibraryScanning(:final cached?)) {
              if (current is LibraryLoaded) _rescanBaseline = cached;
              return current is LibraryLoaded || current is LibraryError;
            }
            return false;
          },
          listener: (context, state) {
            final before = _rescanBaseline;
            _rescanBaseline = null;
            if (state is LibraryError) {
              // The library stays on screen as it was; say it is not fresh.
              AppToast.show(context, context.l10n.libraryRescanFailed);
            } else if (before != null && state is LibraryLoaded) {
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
        // What scans leave out changed (Settings > Library, a restore, a
        // reset): the library follows at once, its toast saying what left
        // or came back.
        BlocListener<SettingsCubit, SettingsState>(
          bloc: getIt<SettingsCubit>(),
          listenWhen: scanFilterChanged,
          listener: (context, _) =>
              context.read<LibraryBloc>().add(const LibraryRefreshRequested()),
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

          final isRootPage = _isRootPage;

          // Songs picked end with the page or the tab shown.
          return SelectionPlace(
            place: (_currentLocation, widget.navigationShell.currentIndex),
            child: TabReselectScope(
              controller: _reselect,
              child: Scaffold(
                backgroundColor: Colors.black,
                body: Stack(
                  children: [
                    const Positioned.fill(child: AmbientBackground()),

                    // ── The Branch Content ─────────────────────────────────────────
                    // Lowered while Now Playing covers it, risen back as
                    // the surface lands in the mini player.
                    Positioned.fill(
                      child: NowPlayingCoveredDrop(
                        child: widget.navigationShell,
                      ),
                    ),

                    // ── Floor: content fades out under the floating bar ─────
                    // As tall as the room pages keep for the bar: content at
                    // rest is never dimmed, only what scrolls under the bar.
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: context.bottomBarInset(tabs: isRootPage),
                      child: const IgnorePointer(child: _BottomFade()),
                    ),

                    // ── Bottom Bar ────────────────────────────────────────────────
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          12,
                          0,
                          12,
                          safeBottom + 12,
                        ),
                        // Songs picked put their actions in the bar.
                        child:
                            BlocSelector<
                              TrackSelectionCubit,
                              TrackSelection,
                              bool
                            >(
                              selector: (selection) => selection.active,
                              builder: (context, picking) => AppBottomNavBar(
                                currentTab: currentTab,
                                onTabChanged: _onTabChanged,
                                showTabs: isRootPage,
                                actions: picking
                                    ? const SelectionActions()
                                    : null,
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Whether a tab's root page is shown, not a page pushed over it.
  /// [_currentLocation] follows both the widget prop and the router
  /// delegate, so it is right after any pop, system back included.
  bool get _isRootPage => [
    AppRoute.home,
    AppRoute.library,
    AppRoute.search,
    AppRoute.playlists,
  ].contains(_currentLocation);

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
            AppIcons.libraryScan,
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

/// The floor under the floating bar: content scrolling down to the screen's
/// edge fades into the page's background instead of being cut by the bar.
/// A gradient, no blur: the bar holds the screen's second blur.
class _BottomFade extends StatelessWidget {
  const _BottomFade();

  @override
  Widget build(BuildContext context) {
    final floor = context.colors.bgPrimary;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            floor.withValues(alpha: 0),
            floor.withValues(alpha: .55),
            floor.withValues(alpha: .85),
          ],
          stops: const [0, .55, 1],
        ),
      ),
    );
  }
}
