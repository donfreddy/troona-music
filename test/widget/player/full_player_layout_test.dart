import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/add_track_to_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/get_likes_playlist_use_case.dart';
import 'package:troona/features/library/domain/use_cases/is_track_in_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/remove_track_from_likes_use_case.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/bloc/sleep_timer/sleep_timer_cubit.dart';
import 'package:troona/features/player/presentation/pages/full_player_page.dart';
import 'package:troona/features/player/presentation/widgets/glass_lens.dart';
import 'package:troona/features/player/presentation/widgets/player_controls.dart';
import 'package:troona/features/player/presentation/widgets/player_utility_dock.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/app_bottom_nav_bar.dart';

import '../../helpers/fake_player.dart';

/// No liked songs.
final class _NoLikes implements LibraryRepository {
  @override
  Future<Either<Failure, Playlist>> getLikesPlaylist() async =>
      right(const Playlist(id: 'likes', name: 'Likes', trackIds: []));

  @override
  Future<Either<Failure, bool>> isTrackInLikes(String trackId) async =>
      right(false);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Screens in logical pixels: a Galaxy S7 class 16:9 phone, the reference
/// design and a tall phone.
const _screens = {
  '360x640': Size(360, 640),
  '390x844': Size(390, 844),
  '412x915': Size(412, 915),
};

void main() {
  final tracks = [
    for (final id in 'abcde'.split('')) testTrack(id, durationMs: 180000),
  ];

  late FakeAudioPort port;

  Future<void> pumpPage(
    WidgetTester tester, {
    required Size screen,
    required double textScale,
  }) async {
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = screen * 3
      // Status bar on top, a gesture bar below.
      ..padding = const FakeViewPadding(top: 72, bottom: 48);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    port = FakeAudioPort()
      ..queue = Queue.fromTracks(tracks, startIndex: 2)
      ..duration = const Duration(minutes: 3);
    final bloc = buildTestPlayerBloc(port, PlaybackSessionStore(prefs));
    final repo = _NoLikes();
    final likes = LikesCubit(
      addTrack: AddTrackToLikesUseCase(repo),
      removeTrack: RemoveTrackFromLikesUseCase(repo),
      isTrackLiked: IsTrackInLikesUseCase(repo),
      getLikesPlaylist: GetLikesPlaylistUseCase(repo),
    );
    final palette = TrackPaletteCubit();
    final sleep = SleepTimerCubit(port: port);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      // Not awaited: under the fake clock the closes never settle.
      unawaited(bloc.close());
      unawaited(likes.close());
      unawaited(palette.close());
      unawaited(sleep.close());
      unawaited(port.close());
    });

    bloc.add(QueueSetRequested(tracks, startIndex: 2));
    await tester.pump();
    port.status.add(PlaybackStatus.playing);
    await tester.pump();
    expect(bloc.state, isA<PlayerActive>());

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: likes),
          BlocProvider.value(value: palette),
          BlocProvider.value(value: sleep),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FullPlayerPage(morphFromMini: false),
        ),
      ),
    );
    // The title marquee repeats forever: settle with bounded pumps.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  for (final MapEntry(key: name, value: screen) in _screens.entries) {
    // 2.0: above the cap, which Now Playing applies itself.
    for (final textScale in [1.0, AppLayout.maxTextScale, 2.0]) {
      testWidgets('$name, text x$textScale: everything fits above the tabs', (
        tester,
      ) async {
        await pumpPage(tester, screen: screen, textScale: textScale);

        // A RenderFlex overflow is reported as an exception.
        expect(tester.takeException(), isNull);
        final tabsTop = tester.getTopLeft(find.byType(AppBottomNavBar)).dy;
        final controls = tester.getRect(find.byType(PlayerControls));
        final dock = tester.getRect(find.byType(PlayerUtilityDock));
        final ring = tester.getRect(find.byType(GlassLens));
        expect(controls.bottom, lessThanOrEqualTo(tabsTop));
        expect(dock.bottom, lessThanOrEqualTo(controls.top));
        expect(ring.bottom, lessThanOrEqualTo(dock.top));
        expect(controls.height, PlayerControls.height);
        expect(dock.height, PlayerUtilityDock.height);
      });
    }
  }

  testWidgets('the ring keeps its full size on a tall screen', (tester) async {
    await pumpPage(tester, screen: const Size(412, 915), textScale: 1);
    final lens = tester.widget<GlassLens>(find.byType(GlassLens));
    expect(lens.diameter, closeTo(412 * 0.80, 0.01));
  });

  testWidgets('the ring shrinks on a short screen', (tester) async {
    await pumpPage(
      tester,
      screen: const Size(360, 640),
      textScale: AppLayout.maxTextScale,
    );
    final lens = tester.widget<GlassLens>(find.byType(GlassLens));
    expect(lens.diameter, lessThan(360 * 0.80));
    expect(lens.diameter, greaterThan(150));
  });

  testWidgets('a split screen leaves the ring out and keeps the controls', (
    tester,
  ) async {
    await pumpPage(tester, screen: const Size(360, 420), textScale: 1);
    expect(tester.takeException(), isNull);
    expect(find.byType(GlassLens), findsNothing);
    final tabsTop = tester.getTopLeft(find.byType(AppBottomNavBar)).dy;
    expect(
      tester.getRect(find.byType(PlayerControls)).bottom,
      lessThanOrEqualTo(tabsTop),
    );
  });

  testWidgets('a track change while the ring is hidden shows when it is back', (
    tester,
  ) async {
    await pumpPage(tester, screen: const Size(360, 420), textScale: 1);
    // The player moves on, from the lock screen for instance.
    const playing = 4;
    port.queueCtrl.add(Queue.fromTracks(tracks, startIndex: playing));
    await tester.pump(const Duration(milliseconds: 300));

    tester.view.physicalSize = const Size(412, 915) * 3;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final page = tester
        .widget<PageView>(find.byType(PageView))
        .controller!
        .page;
    expect(page, playing.toDouble());
  });
}
