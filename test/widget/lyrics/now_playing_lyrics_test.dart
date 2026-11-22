import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:troona/features/player/presentation/pages/full_player_page.dart';
import 'package:troona/features/player/presentation/widgets/artwork_carousel.dart';
import 'package:troona/features/player/presentation/widgets/now_playing_hero.dart';
import 'package:troona/features/player/presentation/widgets/player_progress_bar.dart';
import 'package:troona/l10n/app_localizations.dart';

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
  Future<NavigatorState> pumpOpen(WidgetTester tester) async {
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = const Size(360, 640) * 3;
    addTearDown(tester.view.reset);

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

  testWidgets('the dock shows the lyrics in place of the stage, with a '
      'seek bar; the stage stays mounted, its heroes off', (tester) async {
    await pumpOpen(tester);
    expect(carouselHeroes(tester), isTrue);
    expect(lyrics.asked, isEmpty, reason: 'nothing read until shown');

    await tester.tap(find.byTooltip('Show lyrics'));
    await settle(tester);
    expect(find.text('First line'), findsOneWidget);
    expect(find.byType(PlayerProgressBar), findsOneWidget);
    expect(find.byType(ArtworkCarousel), findsOneWidget);
    expect(carouselHeroes(tester), isFalse);
    expect(lyrics.asked, ['b']);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Hide lyrics'));
    await settle(tester);
    expect(find.text('First line'), findsNothing);
    expect(carouselHeroes(tester), isTrue);
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

  testWidgets('closed with the lyrics open: a fade, no flight, no error; '
      'reopened on the stage', (tester) async {
    final navigator = await pumpOpen(tester);
    await tester.tap(find.byTooltip('Show lyrics'));
    await settle(tester);

    navigator.pop();
    await tester.pump();
    await tester.pump(_open * 0.5);
    // No ring to morph from: nothing flies into the row.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            ((w.decoration as BoxDecoration).color?.toARGB32() ?? 0) &
                    0xFFFFFF ==
                0x07090E,
      ),
      findsNothing,
    );
    await settle(tester);
    expect(find.byType(FullPlayerPage), findsNothing);
    expect(tester.takeException(), isNull);

    await push(tester, navigator);
    expect(find.text('First line'), findsNothing);
    expect(carouselHeroes(tester), isTrue);
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
}
