import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
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
import 'package:troona/features/player/presentation/widgets/now_playing_hero.dart';
import 'package:troona/features/player/presentation/widgets/player_controls.dart';
import 'package:troona/features/player/presentation/widgets/player_utility_dock.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/app_bottom_nav_bar.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/shared/widgets/dynamic_background.dart';

import '../../helpers/test_settings.dart';
import '../../helpers/fake_player.dart';

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

/// As in app_router.dart: Now Playing fades nothing itself at route level.
const _open = Duration(milliseconds: 500);
const _close = Duration(milliseconds: 450);

void main() {
  final tracks = [
    for (final id in 'abcde'.split('')) testTrack(id, durationMs: 180000),
  ];

  tearDown(getIt.reset);

  /// The shell under a pushed Now Playing route; returns its navigator.
  Future<NavigatorState> pumpOpen(WidgetTester tester) async {
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = const Size(412, 915) * 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = PlaybackSessionStore(prefs);
    getIt.registerSingleton(store);
    final port = FakeAudioPort()
      ..queue = Queue.fromTracks(tracks, startIndex: 2)
      ..duration = const Duration(minutes: 3);
    final bloc = buildTestPlayerBloc(port, store);
    final repo = _NoLikes();
    final likes = LikesCubit(
      addTrack: AddTrackToLikesUseCase(repo),
      removeTrack: RemoveTrackFromLikesUseCase(repo),
      isTrackLiked: IsTrackInLikesUseCase(repo),
      getLikesPlaylist: GetLikesPlaylistUseCase(repo),
    );
    final palette = TrackPaletteCubit();
    final sleep = SleepTimerCubit(port: port);
    final settings = await loadedSettings();
    addTearDown(settings.close);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
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

    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: likes),
          BlocProvider.value(value: palette),
          BlocProvider.value(value: sleep),
          BlocProvider.value(value: settings),
        ],
        child: MaterialApp(
          navigatorKey: navigator,
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: Center(child: Text('below'))),
        ),
      ),
    );
    unawaited(
      navigator.currentState!.push(
        PageRouteBuilder<void>(
          transitionDuration: _open,
          reverseTransitionDuration: _close,
          pageBuilder: (_, _, _) => const FullPlayerPage(morphFromMini: false),
        ),
      ),
    );
    // The title marquee repeats forever: settle with bounded pumps.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    return navigator.currentState!;
  }

  /// Opacity the widget reaches the screen with: every fade above it.
  double opacityAbove(WidgetTester tester, Finder finder) => tester
      .widgetList<FadeTransition>(
        find.ancestor(of: finder, matching: find.byType(FadeTransition)),
      )
      .fold(1.0, (product, fade) => product * fade.opacity.value);

  double backdrop(WidgetTester tester) =>
      opacityAbove(tester, find.byType(DynamicBackground));

  testWidgets('dismissing keeps the background opaque while the surface '
      'flies, and lets the chrome and the stage go first', (tester) async {
    final navigator = await pumpOpen(tester);
    expect(backdrop(tester), 1);

    navigator.pop();
    await tester.pump();
    // A fifth of the dismiss: route animation at 0.8.
    await tester.pump(_close * 0.2);
    expect(backdrop(tester), 1);
    expect(
      opacityAbove(tester, find.byType(PlayerControls)),
      closeTo(0.31, 0.05),
      reason: 'the chrome is already mostly gone',
    );
    // The stage (lens, arc, neighbour covers) is gone at a quarter.
    expect(opacityAbove(tester, find.byType(GlassLens)), lessThan(0.5));
    expect(
      opacityAbove(tester, find.byType(ArtworkPlaceholder).first),
      lessThan(0.5),
      reason: 'the neighbour covers go with the lens',
    );

    // Still above 0.45: the page below is not showing yet.
    await tester.pump(_close * 0.3);
    expect(backdrop(tester), 1);
    expect(opacityAbove(tester, find.byType(PlayerControls)), 0);
    expect(opacityAbove(tester, find.byType(ArtworkPlaceholder).first), 0);

    // Past it, the background fades out.
    await tester.pump(_close * 0.3);
    expect(backdrop(tester), allOf(greaterThan(0), lessThan(1)));
    await tester.pumpAndSettle();
    expect(find.byType(FullPlayerPage), findsNothing);
  });

  testWidgets("dismissing opens a mini player slot in the page's own bar, "
      'fully before the background goes', (tester) async {
    final navigator = await pumpOpen(tester);
    double barHeight() => tester.getSize(find.byType(AppBottomNavBar)).height;
    final tabsOnly = barHeight();
    expect(
      tabsOnly,
      lessThan(AppSpacing.navBarHeight + 4),
      reason: 'shut at rest: the tabs and their border',
    );

    navigator.pop();
    await tester.pump();
    // Route animation at 0.9: the surface has barely left the ring.
    await tester.pump(_close * 0.1);
    expect(barHeight(), tabsOnly);

    // At 0.6: opening, while the surface comes down.
    await tester.pump(_close * 0.3);
    expect(
      barHeight(),
      allOf(
        greaterThan(tabsOnly + 8),
        lessThan(tabsOnly + AppSpacing.miniPlayerHeight - 8),
      ),
    );

    // At 0.5: all but open, the background still opaque over the shell.
    await tester.pump(_close * 0.1);
    expect(backdrop(tester), 1);
    expect(
      barHeight(),
      greaterThan(tabsOnly + AppSpacing.miniPlayerHeight * 0.95),
    );

    // At 0.4: as tall as the shell's bar, which the background uncovers.
    await tester.pump(_close * 0.1);
    expect(backdrop(tester), lessThan(1));
    expect(barHeight(), closeTo(tabsOnly + AppSpacing.miniPlayerHeight, 0.01));
    await tester.pumpAndSettle();
    expect(find.byType(FullPlayerPage), findsNothing);
  });

  testWidgets('opening covers the page below within the first 45 %', (
    tester,
  ) async {
    final navigator = await pumpOpen(tester);
    navigator.pop();
    await tester.pumpAndSettle();

    unawaited(
      navigator.push(
        PageRouteBuilder<void>(
          transitionDuration: _open,
          reverseTransitionDuration: _close,
          pageBuilder: (_, _, _) => const FullPlayerPage(morphFromMini: false),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(_open * 0.2);
    expect(backdrop(tester), allOf(greaterThan(0), lessThan(1)));
    await tester.pump(_open * 0.26);
    expect(backdrop(tester), 1);
    expect(
      opacityAbove(tester, find.byType(PlayerControls)),
      0,
      reason: 'the chrome comes last',
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  });

  testWidgets('a drag down moves the content, not the background', (
    tester,
  ) async {
    await pumpOpen(tester);
    final background = tester.getRect(find.byType(DynamicBackground));
    final controls = tester.getRect(find.byType(PlayerControls));

    final gesture = await tester.startGesture(
      controls.centerLeft + const Offset(8, 0),
    );
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, 10));
      await tester.pump();
    }

    expect(tester.getRect(find.byType(DynamicBackground)), background);
    expect(
      tester.getRect(find.byType(PlayerControls)).top - controls.top,
      greaterThan(60),
    );
    await gesture.up();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  });

  testWidgets('a press on the ring lifts the lens and the current cover', (
    tester,
  ) async {
    await pumpOpen(tester);
    final lens = tester.widget<GlassLens>(find.byType(GlassLens));
    final center = tester.getCenter(find.byType(GlassLens));
    final onBand = center - Offset((lens.diameter + lens.holeDiameter) / 4, 0);

    double scaleAbove(Finder finder) => tester
        .widgetList<Transform>(
          find.ancestor(of: finder, matching: find.byType(Transform)),
        )
        .map((t) => t.transform.getMaxScaleOnAxis())
        .reduce((a, b) => a * b);
    // The current cover sits in the lens; a neighbour beside it.
    final covers = find.byType(ArtworkPlaceholder);
    Finder coverWhere(bool Function(double distance) test) => find
        .byElementPredicate(
          (e) =>
              covers.evaluate().contains(e) &&
              test(
                (tester.getCenter(find.byElementPredicate((x) => x == e)) -
                        center)
                    .distance,
              ),
        )
        .first;
    final cover = coverWhere((d) => d < 1);
    final neighbour = coverWhere((d) => d > 20);
    final neighbourScale = scaleAbove(neighbour);

    final gesture = await tester.startGesture(onBand);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    expect(scaleAbove(find.byType(GlassLens)), closeTo(1.06, 1e-6));
    expect(scaleAbove(cover), closeTo(1.06, 1e-6));
    expect(
      scaleAbove(neighbour),
      neighbourScale,
      reason: 'the neighbours stay as they are',
    );

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));
    expect(scaleAbove(find.byType(GlassLens)), 1);
  });

  testWidgets('glass keeps its opacity while dragged, the rest fades', (
    tester,
  ) async {
    await pumpOpen(tester);
    final controls = tester.getRect(find.byType(PlayerControls));
    final gesture = await tester.startGesture(
      controls.centerLeft + const Offset(8, 0),
    );
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, 10));
      await tester.pump();
    }

    Iterable<double> opacitiesAbove(Finder finder) => tester
        .widgetList<FadeTransition>(
          find.ancestor(of: finder, matching: find.byType(FadeTransition)),
        )
        .map((f) => f.opacity.value);
    expect(opacitiesAbove(find.byType(PlayerUtilityDock)), everyElement(1.0));
    expect(opacitiesAbove(find.byType(GlassLens)), everyElement(1.0));
    expect(
      opacitiesAbove(find.byType(PlayerControls)),
      contains(lessThan(1.0)),
    );
    // The covers beside the current one fade with the chrome; the current
    // one, in the lens, does not.
    final center = tester.getCenter(find.byType(GlassLens));
    final covers = find.byType(ArtworkPlaceholder).evaluate().toList();
    for (final cover in covers) {
      final finder = find.byElementPredicate((e) => e == cover);
      final inLens = (tester.getCenter(finder) - center).distance < 1;
      expect(
        opacitiesAbove(finder),
        inLens ? everyElement(1.0) : contains(lessThan(1.0)),
        reason: inLens ? 'current cover' : 'neighbour',
      );
    }
    await gesture.up();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  });

  group('the page under Now Playing', () {
    late AnimationController route;

    Future<double> pumpDrop(
      WidgetTester tester, {
      bool reduceMotion = false,
    }) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: NowPlayingCoveredDrop(child: SizedBox(key: Key('page'))),
          ),
        ),
      );
      return offset(tester);
    }

    setUp(() {
      route = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 450),
      );
    });
    tearDown(() {
      NowPlayingHero.coverAnimation.value = null;
      route.dispose();
    });

    testWidgets('drops only once covered, rises once it shows again, and '
        'settles after the flight', (tester) async {
      NowPlayingHero.coverAnimation.value = route;
      expect(await pumpDrop(tester), 0);

      // Opening: still showing, still in place.
      route.value = 0.5;
      await tester.pump();
      expect(offset(tester), 0);
      route.value = 1;
      await tester.pump();
      expect(offset(tester), NowPlayingHero.coveredDrop);

      // Dismissing: hidden under the background, it stays low...
      route.value = 0.5;
      await tester.pump();
      await tester.pump(NowPlayingCoveredDrop.riseDuration);
      expect(offset(tester), NowPlayingHero.coveredDrop);
      // ...then rises once showing, decelerating into place.
      route.value = 0.2;
      await tester.pump();
      await tester.pump(NowPlayingCoveredDrop.riseDuration * 0.5);
      expect(
        offset(tester),
        allOf(greaterThan(0), lessThan(NowPlayingHero.coveredDrop / 2)),
      );
      await tester.pump(NowPlayingCoveredDrop.riseDuration * 0.5);
      expect(offset(tester), 0);
    });

    testWidgets('rises when Now Playing goes without a flight', (tester) async {
      NowPlayingHero.coverAnimation.value = route..value = 1;
      await pumpDrop(tester);
      expect(offset(tester), NowPlayingHero.coveredDrop);
      NowPlayingHero.coverAnimation.value = null;
      await tester.pump();
      await tester.pump(NowPlayingCoveredDrop.riseDuration);
      expect(offset(tester), 0);
    });

    testWidgets('stays still when the phone asks for less motion', (
      tester,
    ) async {
      NowPlayingHero.coverAnimation.value = route..value = 1;
      expect(await pumpDrop(tester, reduceMotion: true), 0);
    });
  });
}

double offset(WidgetTester tester) =>
    tester.getTopLeft(find.byKey(const Key('page'))).dy;
