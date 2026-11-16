import 'dart:async';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:dartz/dartz.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/add_track_to_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/get_likes_playlist_use_case.dart';
import 'package:troona/features/library/domain/use_cases/is_track_in_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/remove_track_from_likes_use_case.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/app_bottom_nav_bar.dart';

import '../../helpers/fake_player.dart';

final class _Likes implements LibraryRepository {
  final liked = <String>{};

  @override
  Future<Either<Failure, Playlist>> getLikesPlaylist() async =>
      right(Playlist(id: 'likes', name: 'Likes', trackIds: [...liked]));

  @override
  Future<Either<Failure, bool>> isTrackInLikes(String trackId) async =>
      right(liked.contains(trackId));

  @override
  Future<Either<Failure, Unit>> addTrackToLikes(String trackId) async {
    liked.add(trackId);
    return right(unit);
  }

  @override
  Future<Either<Failure, Unit>> removeTrackFromLikes(String trackId) async {
    liked.remove(trackId);
    return right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeAudioPort port;
  late _Likes likes;

  Future<PlayerBloc> pump(
    WidgetTester tester,
    AppTab tab, {
    List<Track>? queue,
    int start = 0,
    bool reduceMotion = false,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    port = FakeAudioPort();
    final bloc = buildTestPlayerBloc(port, PlaybackSessionStore(prefs));
    if (queue != null) {
      port
        ..queue = Queue.fromTracks(queue, startIndex: start)
        ..duration = const Duration(minutes: 3);
      bloc.add(QueueSetRequested(queue, startIndex: start));
      await tester.pump();
      port.status.add(PlaybackStatus.playing);
      await tester.pump();
    }
    likes = _Likes();
    final likesCubit = LikesCubit(
      addTrack: AddTrackToLikesUseCase(likes),
      removeTrack: RemoveTrackFromLikesUseCase(likes),
      isTrackLiked: IsTrackInLikesUseCase(likes),
      getLikesPlaylist: GetLikesPlaylistUseCase(likes),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      unawaited(bloc.close());
      unawaited(likesCubit.close());
      unawaited(port.close());
    });
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: likesCubit),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: AppBottomNavBar(currentTab: tab, onTabChanged: (_) {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return bloc;
  }

  /// Scale of the dot of each tab, in tab order.
  List<double> dotScales(WidgetTester tester) => [
    for (final element in find.byKey(const ValueKey('tabDot')).evaluate())
      tester
          .widget<AnimatedScale>(
            find.ancestor(
              of: find.byWidget(element.widget),
              matching: find.byType(AnimatedScale),
            ),
          )
          .scale,
  ];

  testWidgets('a dot shows under the selected tab only, and follows it', (
    tester,
  ) async {
    await pump(tester, AppTab.home);
    expect(dotScales(tester), [1, 0, 0, 0]);

    await pump(tester, AppTab.search);
    expect(dotScales(tester), [0, 0, 1, 0]);
  });

  testWidgets('the dot sits under its icon, which stays centred in the row', (
    tester,
  ) async {
    await pump(tester, AppTab.library);
    final icon = tester.getRect(find.byIcon(AppIcons.library));
    final dot = tester.getRect(find.byKey(const ValueKey('tabDot')).at(1));
    expect(dot.center.dx, closeTo(icon.center.dx, .01));
    expect(dot.top, greaterThan(icon.bottom));

    // Same height as the tabs without a dot.
    final home = tester.getRect(find.byIcon(AppIcons.home));
    expect(icon.center.dy, home.center.dy);
  });

  testWidgets('screen readers still hear which tab is selected', (
    tester,
  ) async {
    await pump(tester, AppTab.playlists);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AppBottomNavBar)),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel(l10n.navPlaylists)),
      matchesSemantics(
        label: l10n.navPlaylists,
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('a swipe on the mini player\'s song plays the next one, or '
      'the previous one', (tester) async {
    final tracks = [
      for (final id in ['a', 'b', 'c']) testTrack(id, durationMs: 60000),
    ];
    final bloc = await pump(tester, AppTab.home, queue: tracks, start: 1);
    expect((bloc.state as PlayerActive).currentTrack.id, 'b');

    Future<void> swipe(double dx) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Title b')),
      );
      for (var i = 0; i < 12; i++) {
        await gesture.moveBy(Offset(dx / 12, 0));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await tester.pumpAndSettle();
    }

    await swipe(-120);
    expect(port.skipNextCalls, 1);
    await swipe(120);
    // The previous song itself, not back to the start of this one.
    expect(port.indexJumps, [0]);
    expect(port.skipPreviousCalls, 0);

    // Short: nothing.
    await swipe(-40);
    expect(port.skipNextCalls, 1);
  });

  testWidgets('a long press on the mini player likes the song, and again '
      'takes it back', (tester) async {
    await pump(tester, AppTab.home, queue: [testTrack('a', durationMs: 60000)]);
    final burst = find.byKey(const ValueKey('likeBurst'));

    await tester.longPress(find.text('Title a'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(likes.liked, {'a'});
    expect(burst, findsOneWidget);
    expect(find.text('Added to Liked songs'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(burst, findsNothing, reason: 'the heart fades away');

    await tester.longPress(find.text('Title a'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(likes.liked, isEmpty);
    expect(find.text('Removed from Liked songs'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Next keeps its button.
    expect(find.byTooltip('Next'), findsOneWidget);
  });

  testWidgets('screen readers get the like as an action', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, AppTab.home, queue: [testTrack('a', durationMs: 60000)]);

    final node = tester.getSemantics(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.customSemanticsActions != null,
      ),
    );
    final labels = [
      for (final id in node.getSemanticsData().customSemanticsActionIds!)
        CustomSemanticsAction.getAction(id)?.label,
    ];
    expect(labels, contains('Like'));
    handle.dispose();
  });

  testWidgets('no heart with reduced motion: the toast says it', (
    tester,
  ) async {
    await pump(
      tester,
      AppTab.home,
      queue: [testTrack('a', durationMs: 60000)],
      reduceMotion: true,
    );

    await tester.longPress(find.text('Title a'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(likes.liked, {'a'});
    expect(find.byKey(const ValueKey('likeBurst')), findsNothing);
    expect(find.text('Added to Liked songs'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });
}
