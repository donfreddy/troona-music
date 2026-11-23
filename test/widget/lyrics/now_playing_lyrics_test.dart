import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/features/lyrics/presentation/widgets/keep_screen_on.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/add_track_to_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/get_likes_playlist_use_case.dart';
import 'package:troona/features/library/domain/use_cases/is_track_in_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/remove_track_from_likes_use_case.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics_lookup.dart';
import 'package:troona/features/lyrics/domain/repositories/lyrics_repository.dart';
import 'package:troona/features/lyrics/domain/services/lrc_parser.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/bloc/sleep_timer/sleep_timer_cubit.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/player/presentation/pages/full_player_page.dart';
import 'package:troona/shared/widgets/app_bottom_nav_bar.dart';
import 'package:troona/features/player/presentation/widgets/player_controls.dart';
import 'package:troona/features/lyrics/presentation/widgets/lyrics_view.dart';
import 'package:troona/features/player/presentation/widgets/artwork_carousel.dart';
import 'package:troona/features/player/presentation/widgets/now_playing_hero.dart';
import 'package:troona/features/player/presentation/widgets/player_progress_bar.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/dynamic_background.dart';
import 'package:troona/shared/widgets/palette_ink_scope.dart';

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

/// Every song has the same synced lyrics.
final class _Lyrics implements LyricsRepository {
  final asked = <String>[];
  final deleted = <String>[];
  LyricsLookup answer = LyricsFound(
    LrcParser.parse(
      '[00:01.00]First line\n[00:04.00]Second line',
      source: LyricsSource.online,
    )!,
  );

  @override
  Future<LyricsLookup> lyricsFor(
    Track track, {
    bool searchAgain = false,
  }) async {
    asked.add(track.id);
    return answer;
  }

  @override
  Future<Either<Failure, Unit>> delete(String trackId) async {
    deleted.add(trackId);
    return right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _open = Duration(milliseconds: 500);

void main() {
  final tracks = [
    for (final id in 'abc'.split(''))
      testTrack(id, durationMs: 180000)..artworkPath = '/none/$id.jpg',
  ];
  late _Lyrics lyrics;
  late FakeAudioPort port;
  late SettingsCubit settings;

  Future<void> settle(WidgetTester tester) async {
    // The title marquee repeats forever: bounded pumps.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> push(WidgetTester tester, NavigatorState navigator) async {
    unawaited(
      navigator.push(
        PageRouteBuilder<void>(
          opaque: false,
          transitionDuration: _open,
          reverseTransitionDuration: _open,
          pageBuilder: (_, _, _) => const FullPlayerPage(),
        ),
      ),
    );
    await settle(tester);
  }

  /// A shell with the mini player's two heroes, under a pushed Now
  /// Playing: closing it would morph the ring into the row.
  Future<NavigatorState> pumpOpen(
    WidgetTester tester, {
    double textScale = 1,
  }) async {
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = const Size(360, 640) * 3;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    SharedPreferences.setMockInitialValues({});
    final store = PlaybackSessionStore(await SharedPreferences.getInstance());
    lyrics = _Lyrics();
    getIt
      ..registerSingleton(store)
      ..registerSingleton<LyricsRepository>(lyrics);
    addTearDown(() async {
      await getIt.unregister<PlaybackSessionStore>();
      await getIt.unregister<LyricsRepository>();
    });
    port = FakeAudioPort()
      ..queue = Queue.fromTracks(tracks, startIndex: 1)
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
    settings = await loadedSettings();
    addTearDown(settings.close);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      unawaited(bloc.close());
      unawaited(likes.close());
      unawaited(palette.close());
      unawaited(sleep.close());
      unawaited(port.close());
    });

    bloc.add(QueueSetRequested(tracks, startIndex: 1));
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
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: 336,
                height: 64,
                child: Stack(
                  children: [
                    Hero(
                      tag: NowPlayingHero.surfaceTag,
                      createRectTween: NowPlayingHero.flightTween,
                      flightShuttleBuilder: NowPlayingHero.surfaceShuttle,
                      child: SizedBox.expand(),
                    ),
                    Positioned(
                      left: 12,
                      top: 11,
                      width: 42,
                      height: 42,
                      child: Hero(
                        tag: NowPlayingHero.artworkTag,
                        createRectTween: NowPlayingHero.flightTween,
                        flightShuttleBuilder: NowPlayingHero.artworkShuttle,
                        child: SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await push(tester, navigator.currentState!);
    return navigator.currentState!;
  }

  bool carouselHeroes(WidgetTester tester) =>
      tester.widget<ArtworkCarousel>(find.byType(ArtworkCarousel)).enableHeroes;

  double opacityAbove(WidgetTester tester, Finder finder) => tester
      .widgetList<FadeTransition>(
        find.ancestor(of: finder, matching: find.byType(FadeTransition)),
      )
      .map((f) => f.opacity.value)
      .reduce((a, b) => a * b);

  testWidgets('the dock shows the lyrics in place of the stage, with a '
      'seek bar; the stage stays mounted, unseen, its heroes on', (
    tester,
  ) async {
    await pumpOpen(tester);
    expect(carouselHeroes(tester), isTrue);
    expect(lyrics.asked, isEmpty, reason: 'nothing read until shown');

    await tester.tap(find.byTooltip('Show lyrics'));
    await settle(tester);
    expect(find.text('First line'), findsOneWidget);
    expect(find.byType(PlayerProgressBar), findsOneWidget);
    expect(find.byType(ArtworkCarousel), findsOneWidget);
    expect(opacityAbove(tester, find.byType(ArtworkCarousel)), 0);
    expect(carouselHeroes(tester), isTrue, reason: 'the page still morphs');
    expect(lyrics.asked, ['b']);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Hide lyrics'));
    await settle(tester);
    expect(find.text('First line'), findsNothing);
    expect(opacityAbove(tester, find.byType(ArtworkCarousel)), 1);
  });

  testWidgets('the lyrics keep the screen on while they play, unless '
      'Settings turned it off', (tester) async {
    bool held() =>
        tester.widget<KeepScreenOn>(find.byType(KeepScreenOn)).active;

    await pumpOpen(tester);
    await tester.tap(find.byTooltip('Show lyrics'));
    await settle(tester);
    expect(held(), isTrue);

    await settings.setLyricsKeepScreenOn(false);
    await settle(tester);
    expect(held(), isFalse);

    await settings.setLyricsKeepScreenOn(true);
    await settle(tester);
    expect(held(), isTrue, reason: 'turned back on while playing');

    port.status.add(PlaybackStatus.paused);
    await settle(tester);
    expect(held(), isFalse, reason: 'paused');
  });

  testWidgets('the stage and the lyrics cross-fade: never a cut, never both '
      'at full strength', (tester) async {
    await pumpOpen(tester);
    await tester.tap(find.byTooltip('Show lyrics'));
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      final stage = opacityAbove(tester, find.byType(ArtworkCarousel));
      final words = find.byType(LyricsView).evaluate().isEmpty
          ? 0.0
          : opacityAbove(tester, find.byType(LyricsView));
      expect(
        stage < 1 || words == 0,
        isTrue,
        reason: 'step $i: the stage has begun to go before the words come',
      );
      expect(stage * words, lessThan(0.3), reason: 'step $i');
    }
    await settle(tester);
    expect(opacityAbove(tester, find.byType(ArtworkCarousel)), 0);
  });

  testWidgets('the controls slide down as the lyrics take the room, and the '
      'tab bar goes off the screen', (tester) async {
    await pumpOpen(tester);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final before = tester.getTopLeft(find.byType(PlayerControls)).dy;
    Rect bar() => tester.getRect(find.byType(AppBottomNavBar).last);
    expect(bar().top, lessThan(screen.height));

    await tester.tap(find.byTooltip('Show lyrics'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 170));
    final midway = tester.getTopLeft(find.byType(PlayerControls)).dy;
    await settle(tester);
    final after = tester.getTopLeft(find.byType(PlayerControls)).dy;
    expect(after, greaterThan(before), reason: 'the bar left them its room');
    expect(midway, inExclusiveRange(before, after), reason: 'no jump');
    expect(bar().top, greaterThanOrEqualTo(screen.height));

    await tester.tap(find.byTooltip('Hide lyrics'));
    await settle(tester);
    expect(tester.getTopLeft(find.byType(PlayerControls)).dy, before);
    expect(bar().top, lessThan(screen.height));
  });

  testWidgets('the lyrics take their ink from the glow behind them: '
      'the same palette, the same tone, so they move in step', (tester) async {
    await pumpOpen(tester);
    await tester.tap(find.byTooltip('Show lyrics'));
    await settle(tester);
    final background = tester.widget<DynamicBackground>(
      find.byType(DynamicBackground),
    );
    final scope = tester.widget<PaletteInkScope>(find.byType(PaletteInkScope));
    expect(scope.colorA, background.colorA);
    expect(scope.colorB, background.colorB);
    expect(scope.tone, background.tone);
    expect(
      find.descendant(
        of: find.byType(PaletteInkScope),
        matching: find.text('First line'),
      ),
      findsOneWidget,
    );
    // The seek bar's times are small text over the glow: its tint too.
    final time = find
        .descendant(
          of: find.byType(PlayerProgressBar),
          matching: find.byType(Text),
        )
        .first;
    expect(
      tester.widget<Text>(time).style?.color,
      PaletteInkScope.of(tester.element(time)).secondary,
    );
  });

  testWidgets('a tap on a line seeks there', (tester) async {
    await pumpOpen(tester);
    await tester.tap(find.byTooltip('Show lyrics'));
    await settle(tester);
    await tester.tap(find.text('Second line'));
    // The player sends seeks after a short pause.
    await tester.pump(const Duration(milliseconds: 200));
    expect(port.seeks.last, const Duration(seconds: 4));
  });

  /// The surface shuttle of the flight into the mini player, if flying.
  Finder shuttle() => find.byWidgetPredicate(
    (w) =>
        w is DecoratedBox &&
        w.decoration is BoxDecoration &&
        ((w.decoration as BoxDecoration).color?.toARGB32() ?? 0) & 0xFFFFFF ==
            0x07090E,
  );

  double shuttleAlpha(WidgetTester tester) =>
      ((tester.widget<DecoratedBox>(shuttle()).decoration as BoxDecoration)
          .color!
          .a);

  testWidgets('closed from the stage, the surface leaves it whole', (
    tester,
  ) async {
    final navigator = await pumpOpen(tester);
    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(shuttleAlpha(tester), greaterThan(0.6));
    await settle(tester);
  });

  testWidgets('closed from the lyrics, the surface comes out of them: unseen '
      'as it leaves, then there', (tester) async {
    final navigator = await pumpOpen(tester);
    await tester.tap(find.byTooltip('Show lyrics'));
    await settle(tester);
    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final leaving = shuttleAlpha(tester);
    expect(leaving, lessThan(0.2));
    await tester.pump(_open * 0.6);
    expect(shuttleAlpha(tester), greaterThan(0.6));
    await settle(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('off the screen, the tab bar is not read out either', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpOpen(tester);
    int tabs() => find.semantics.byLabel(RegExp('Library')).evaluate().length;
    final shown = tabs();
    printOnFailure('tabs read: $shown');
    expect(shown, greaterThan(0));
    await tester.tap(find.byTooltip('Show lyrics'));
    await settle(tester);
    expect(tabs(), 0);
    await tester.tap(find.byTooltip('Hide lyrics'));
    await settle(tester);
    expect(tabs(), shown);
    handle.dispose();
  });

  testWidgets('closed with the lyrics open: the page still morphs into the '
      'mini player, and the tab bar is back for the landing', (tester) async {
    final navigator = await pumpOpen(tester);
    await tester.tap(find.byTooltip('Show lyrics'));
    await settle(tester);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;

    navigator.pop();
    await tester.pump();
    await tester.pump(_open * 0.5);
    expect(shuttle(), findsOneWidget, reason: 'the surface flies');
    expect(
      tester.getRect(find.byType(AppBottomNavBar).last).top,
      lessThan(screen.height),
      reason: 'the bar came back up for the surface to land in',
    );
    await settle(tester);
    expect(find.byType(FullPlayerPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('left on its lyrics, Now Playing opens on them again; left on '
      'the stage, on the stage', (tester) async {
    final navigator = await pumpOpen(tester);
    await tester.tap(find.byTooltip('Show lyrics'));
    await settle(tester);
    navigator.pop();
    await settle(tester);

    await push(tester, navigator);
    expect(find.text('First line'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Hide lyrics'));
    await settle(tester);
    navigator.pop();
    await settle(tester);
    await push(tester, navigator);
    expect(find.text('First line'), findsNothing);
    navigator.pop();
    await settle(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no lyrics: says so and offers an import and the search', (
    tester,
  ) async {
    await pumpOpen(tester);
    lyrics.answer = const LyricsMissing(onlineEnabled: false);
    await tester.tap(find.byTooltip('Show lyrics'));
    await settle(tester);
    expect(find.text('No lyrics for this song'), findsOneWidget);
    // Button labels are rich text, beside their icon.
    expect(
      find.textContaining('Import a .lrc file', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Turn on lyrics search', findRichText: true),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('plain lyrics say they are not synced', (tester) async {
    await pumpOpen(tester);
    lyrics.answer = const LyricsFound(
      PlainLyrics('Words only', source: LyricsSource.online),
    );
    await tester.tap(find.byTooltip('Show lyrics'));
    await settle(tester);
    expect(find.text('Not synced'), findsOneWidget);
    expect(find.text('Words only'), findsOneWidget);
  });

  for (final scale in [1.3, 2.0]) {
    for (final (what, answer) in <(String, LyricsLookup)>[
      (
        'synced',
        LyricsFound(
          LrcParser.parse(
            [
              for (var i = 0; i < 30; i++)
                '[00:${(i * 3).toString().padLeft(2, '0')}.00]A line of '
                    'lyrics long enough to wrap twice on a small phone $i',
            ].join('\n'),
            source: LyricsSource.online,
          )!,
        ),
      ),
      (
        'plain',
        LyricsFound(
          PlainLyrics(
            List.filled(30, 'Words only, a long line that wraps').join('\n'),
            source: LyricsSource.online,
          ),
        ),
      ),
      ('none', const LyricsMissing(onlineEnabled: false)),
    ]) {
      testWidgets('360 x 640, text x$scale, $what: nothing overflows', (
        tester,
      ) async {
        await pumpOpen(tester, textScale: scale);
        lyrics.answer = answer;
        await tester.tap(find.byTooltip('Show lyrics'));
        await settle(tester);
        expect(tester.takeException(), isNull);
        expect(find.byType(PlayerProgressBar), findsOneWidget);
      });
    }
  }

  testWidgets('Remove confirmed once another song plays removes the song '
      'the menu was opened for', (tester) async {
    await pumpOpen(tester);
    await tester.tap(find.byTooltip('Show lyrics'));
    await settle(tester);
    // The lyrics menu is in the song's own.
    expect(find.byTooltip('Lyrics options'), findsNothing);
    await tester.tap(find.byIcon(AppIcons.moreVertical));
    await settle(tester);
    await tester.tap(find.text('Lyrics options'));
    await settle(tester);
    await tester.tap(find.text('Remove lyrics'));
    await settle(tester);
    expect(find.text('Remove these lyrics?'), findsOneWidget);

    // The song ends while the dialog asks.
    port
      ..queue = Queue.fromTracks(tracks, startIndex: 2)
      ..track.add(tracks[2]);
    await settle(tester);
    expect(lyrics.asked, ['b', 'c'], reason: 'the song changed');
    await tester.tap(find.text('Remove lyrics').last);
    await settle(tester);
    expect(lyrics.deleted, ['b']);
  });
}
