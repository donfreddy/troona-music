import 'dart:async';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/add_track_to_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/get_likes_playlist_use_case.dart';
import 'package:troona/features/library/domain/use_cases/is_track_in_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/remove_track_from_likes_use_case.dart';
import 'package:troona/features/library/presentation/widgets/track_list_tile.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/l10n/app_localizations.dart';

import '../../helpers/fake_player.dart';

/// No song liked: enough for the track menu to open.
final class _NoLikes implements LibraryRepository {
  @override
  Future<Either<Failure, Playlist>> getLikesPlaylist() async =>
      right(const Playlist(id: 'likes', name: 'Likes', trackIds: []));

  @override
  Future<Either<Failure, bool>> isTrackInLikes(String trackId) async =>
      right(false);

  @override
  Future<Either<Failure, Unit>> addTrackToLikes(String trackId) async =>
      right(unit);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final playing = [
    for (final id in ['a', 'b']) testTrack(id, durationMs: 60000),
  ];
  final song = testTrack('x', durationMs: 60000);

  late PlayerBloc player;

  Future<FakeAudioPort> pump(WidgetTester tester, {bool idle = false}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final port = FakeAudioPort()
      ..queue = Queue.fromTracks(playing, startIndex: 0)
      ..duration = const Duration(minutes: 1);
    final bloc = buildTestPlayerBloc(port, PlaybackSessionStore(prefs));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      unawaited(bloc.close());
      unawaited(port.close());
    });
    player = bloc;
    if (!idle) {
      bloc.add(QueueSetRequested(playing));
      await tester.pump();
      port.status.add(PlaybackStatus.playing);
      await tester.pump();
    }

    final likes = _NoLikes();
    final likesCubit = LikesCubit(
      addTrack: AddTrackToLikesUseCase(likes),
      removeTrack: RemoveTrackFromLikesUseCase(likes),
      isTrackLiked: IsTrackInLikesUseCase(likes),
      getLikesPlaylist: GetLikesPlaylistUseCase(likes),
    );
    addTearDown(likesCubit.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: likesCubit),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: [TrackListTile(track: song, onTap: () {})],
            ),
          ),
        ),
      ),
    );
    return port;
  }

  Future<void> swipe(WidgetTester tester, double dx) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Title x')),
    );
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(Offset(dx / 12, 0));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('swiped right, the song plays next', (tester) async {
    final port = await pump(tester);
    await swipe(tester, 120);
    expect(port.queueEdits.first, 'start add x@1');
    expect(find.text('Plays next'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('swiped left, it goes to the end of the queue', (tester) async {
    final port = await pump(tester);
    await swipe(tester, -120);
    expect(port.queueEdits.first, startsWith('start add x@'));
    expect(port.queue!.playbackTracks.last.id, 'x');
    expect(find.text('Added to queue'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('refused by the player, no message says it was queued', (
    tester,
  ) async {
    for (final dx in [120.0, -120.0]) {
      final port = await pump(tester)
        ..failEdits = true;
      await swipe(tester, dx);
      expect(port.queue!.playbackTracks.map((t) => t.id), ['a', 'b']);
      expect(find.text('Plays next'), findsNothing);
      expect(find.text('Added to queue'), findsNothing);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    }
  });

  testWidgets('with nothing playing, either swipe plays the song, and no '
      'message says it was queued', (tester) async {
    for (final dx in [120.0, -120.0]) {
      await pump(tester, idle: true);
      await swipe(tester, dx);
      expect((player.state as PlayerLoading).track.id, 'x');
      expect(find.text('Plays next'), findsNothing);
      expect(find.text('Added to queue'), findsNothing);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    }
  });

  testWidgets('screen readers get both as actions of the row', (tester) async {
    await pump(tester);
    final semantics = tester.getSemantics(find.text('Title x'));
    final all = <String>{};
    SemanticsNode? node = semantics;
    while (node != null) {
      for (final id
          in node.getSemanticsData().customSemanticsActionIds ??
              const <int>[]) {
        all.add(CustomSemanticsAction.getAction(id)!.label!);
      }
      node = node.parent;
    }
    expect(all, containsAll(['Play next', 'Add to queue']));
  });

  testWidgets('a long press ticks once: the menu opening is the tick', (
    tester,
  ) async {
    final ticks = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') ticks.add(call.arguments);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pump(tester);
    await tester.longPress(find.byType(TrackListTile));
    await tester.pumpAndSettle();
    expect(ticks, hasLength(1));
  });

  testWidgets('a like from the menu pops the heart on the row it came from', (
    tester,
  ) async {
    await pump(tester);
    await tester.longPress(find.byType(TrackListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Like'));
    // The menu closes, then runs the action.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.descendant(
        of: find.byType(TrackListTile),
        matching: find.byKey(const ValueKey('likeBurst')),
      ),
      findsOneWidget,
    );
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });
}
