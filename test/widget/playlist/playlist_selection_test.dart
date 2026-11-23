import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/add_track_to_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/get_likes_playlist_use_case.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_by_ids_use_case.dart';
import 'package:troona/features/library/domain/use_cases/is_track_in_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/remove_track_from_likes_use_case.dart';
import 'package:troona/features/library/presentation/bloc/selection/track_selection_cubit.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:troona/features/playlist/presentation/bloc/playlist_detail/playlist_detail_bloc.dart';
import 'package:troona/features/playlist/presentation/widgets/playlist_detail_page.dart';
import 'package:troona/l10n/app_localizations.dart';

import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import '../../helpers/fake_player.dart';

/// One playlist, held in memory, reordered in place.
final class _Playlists extends Fake implements PlaylistRepository {
  _Playlists(this.tracks);

  final List<Track> tracks;
  final reorders = <(int, int)>[];

  @override
  Future<Either<Failure, Playlist>> getPlaylistById(String id) async => right(
    Playlist(id: id, name: 'Mix', trackIds: [for (final t in tracks) t.id]),
  );

  @override
  Future<Either<Failure, List<Track>>> getTracksByPlaylistId(String id) async =>
      right(List.of(tracks));

  @override
  Future<Either<Failure, Unit>> reorderTracks(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    reorders.add((oldIndex, newIndex));
    tracks.insert(newIndex, tracks.removeAt(oldIndex));
    return right(unit);
  }
}

/// No song liked, and no song read back for the playlist's mosaic.
final class _NoLikes extends Fake implements LibraryRepository {
  @override
  Future<Either<Failure, Playlist>> getLikesPlaylist() async =>
      right(const Playlist(id: 'likes', name: 'Likes', trackIds: []));

  @override
  Future<Either<Failure, List<Track>>> getTracksByIds(List<String> ids) async =>
      right(const []);
}

void main() {
  late LibraryBloc libraryBloc;
  late TrackSelectionCubit selection;
  late PlaylistDetailBloc detail;
  late _Playlists repo;

  Future<void> pump(WidgetTester tester) async {
    final (:player, port: _) = await testPlayer(addTearDown);
    repo = _Playlists([
      for (final id in ['a', 'b', 'c']) testTrack(id, durationMs: 60000),
    ]);
    detail = PlaylistDetailBloc(repo: repo)
      ..add(const PlaylistDetailRequested('p'));
    selection = TrackSelectionCubit();
    final palette = TrackPaletteCubit();
    final likes = _NoLikes();
    getIt.registerSingleton(GetTracksByIdsUseCase(likes));
    addTearDown(() => getIt.unregister<GetTracksByIdsUseCase>());
    final likesCubit = LikesCubit(
      addTrack: AddTrackToLikesUseCase(likes),
      removeTrack: RemoveTrackFromLikesUseCase(likes),
      isTrackLiked: IsTrackInLikesUseCase(likes),
      getLikesPlaylist: GetLikesPlaylistUseCase(likes),
    );
    libraryBloc = idleLibraryBloc();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      unawaited(detail.close());
      unawaited(selection.close());
      unawaited(palette.close());
      unawaited(likesCubit.close());
      unawaited(libraryBloc.close());
    });
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<PlayerBloc>.value(value: player),
          BlocProvider<PlaylistDetailBloc>.value(value: detail),
          BlocProvider<TrackSelectionCubit>.value(value: selection),
          BlocProvider<TrackPaletteCubit>.value(value: palette),
          BlocProvider<LikesCubit>.value(value: likesCubit),
          BlocProvider<LibraryBloc>.value(value: libraryBloc),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PlaylistDetailPage(id: 'p'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<String> picked() => [for (final t in selection.state.tracks) t.id];

  Finder handleOf(String id) => find.descendant(
    of: find.ancestor(
      of: find.text('Title $id'),
      matching: find.byType(InkWell),
    ),
    matching: find.byIcon(AppIcons.dragHandle),
  );

  Future<void> drag(WidgetTester tester, String id, double dy) async {
    final gesture = await tester.startGesture(tester.getCenter(handleOf(id)));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(Offset(0, dy / 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('a long press picks, the handle and options step aside', (
    tester,
  ) async {
    await pump(tester);
    await tester.longPress(find.text('Title b'));
    await tester.pumpAndSettle();
    expect(picked(), ['b']);

    await tester.tap(find.text('Title a'));
    await tester.pumpAndSettle();
    expect(picked(), ['a', 'b']);

    // The handle moves nothing while picking, and the options are out of
    // reach.
    await drag(tester, 'c', -150);
    expect(repo.reorders, isEmpty);
    await tester.tap(find.byTooltip('More options').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Remove from playlist'), findsNothing);
  });

  testWidgets('not picking, the handle moves a row', (tester) async {
    await pump(tester);
    await drag(tester, 'c', -150);
    expect(repo.reorders, isNotEmpty);
    expect(selection.state.active, isFalse);
  });

  testWidgets('a reload keeps the songs picked', (tester) async {
    await pump(tester);
    await tester.longPress(find.text('Title b'));
    await tester.pumpAndSettle();
    detail.add(const PlaylistDetailRequested('p'));
    await tester.pumpAndSettle();
    expect(picked(), ['b']);
  });

  testWidgets('a scan reloads the page, so a move counts on its rows', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Title c'), findsOneWidget);
    // A folder turned off took c out of the library.
    repo.tracks.removeLast();
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    libraryBloc.emit(
      const LibraryLoaded(
        allTracks: [],
        allAlbums: [],
        allArtists: [],
        visibleTracks: [],
        visibleAlbums: [],
        visibleArtists: [],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Title c'), findsNothing);
  });
}
