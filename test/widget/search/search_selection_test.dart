import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_use_case.dart';
import 'package:troona/features/library/domain/use_cases/scan_library_use_case.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/library/presentation/bloc/selection/track_selection_cubit.dart';
import 'package:troona/features/library/presentation/widgets/selection/selection_bar.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/search/domain/entities/search_result.dart';
import 'package:troona/features/search/domain/repositories/search_repository.dart';
import 'package:troona/features/search/presentation/bloc/search_bloc.dart';
import 'package:troona/features/search/presentation/pages/search_page.dart';
import 'package:troona/features/search/presentation/widgets/search_top_result.dart';
import 'package:troona/l10n/app_localizations.dart';

import '../../helpers/fake_player.dart';

class _UnusedLibrary extends Fake implements LibraryRepository {
  @override
  void cancelScan() {}
}

class _UnusedSearch extends Fake implements SearchRepository {}

void main() {
  final songs = [
    for (final id in ['a', 'b', 'c']) testTrack(id, durationMs: 60000),
  ];

  late TrackSelectionCubit selection;
  late SearchBloc search;

  /// The Search page, showing [results] when given, else the suggestions
  /// (the library's newest songs).
  Future<void> pump(WidgetTester tester, {List<Track>? results}) async {
    final (:player, port: _) = await testPlayer(addTearDown);
    final library = LibraryBloc(
      scanLibrary: ScanLibraryUseCase(_UnusedLibrary()),
      getTracks: GetTracksUseCase(_UnusedLibrary()),
    );
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    library.emit(
      LibraryLoaded(
        allTracks: songs,
        allAlbums: const [],
        allArtists: const [],
        visibleTracks: songs,
        visibleAlbums: const [],
        visibleArtists: const [],
      ),
    );
    search = SearchBloc(repo: _UnusedSearch());
    if (results != null) {
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      search.emit(
        SearchLoaded(
          SearchResult(tracks: results, artists: const [], albums: const []),
          'title',
        ),
      );
    }
    selection = TrackSelectionCubit();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      unawaited(library.close());
      unawaited(search.close());
      unawaited(selection.close());
    });
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<PlayerBloc>.value(value: player),
          BlocProvider<LibraryBloc>.value(value: library),
          BlocProvider<SearchBloc>.value(value: search),
          BlocProvider<TrackSelectionCubit>.value(value: selection),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SearchPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<String> picked() => [for (final t in selection.state.tracks) t.id];

  bool fieldCovered(WidgetTester tester) => tester
      .widgetList<IgnorePointer>(
        find.ancestor(
          of: find.byType(TextField),
          matching: find.byType(IgnorePointer),
        ),
      )
      .any((p) => p.ignoring);

  /// The top result: the first song's title, larger, above the songs.
  bool topResultCovered(WidgetTester tester) => tester
      .widgetList<IgnorePointer>(
        find.ancestor(
          of: find.byType(SearchTopResult),
          matching: find.byType(IgnorePointer),
        ),
      )
      .followedBy(
        tester.widgetList<IgnorePointer>(
          find.descendant(
            of: find.byType(SearchTopResult),
            matching: find.byType(IgnorePointer),
          ),
        ),
      )
      .any((p) => p.ignoring);

  testWidgets('results: a long press picks among them, the bar takes the '
      'field', (tester) async {
    await pump(tester, results: [songs[2], songs[0]]);
    expect(fieldCovered(tester), isFalse);
    expect(topResultCovered(tester), isFalse);

    await tester.longPress(find.text('Title a'));
    await tester.pumpAndSettle();
    expect(picked(), ['a']);
    expect(find.byType(SelectionBar), findsOneWidget);
    expect(fieldCovered(tester), isTrue);
    // The top result, which plays its song, is out of reach meanwhile.
    expect(topResultCovered(tester), isTrue);

    // Select all takes the results, in their order, not the library.
    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    expect(picked(), ['c', 'a']);

    await tester.tap(find.byTooltip('End selection'));
    await tester.pumpAndSettle();
    expect(find.byType(SelectionBar), findsNothing);
    expect(fieldCovered(tester), isFalse);
  });

  testWidgets('suggestions: a long press picks among the newest songs', (
    tester,
  ) async {
    await pump(tester);
    await tester.longPress(find.text('Title b'));
    await tester.pumpAndSettle();
    expect(picked(), ['b']);
    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    expect(picked().toSet(), {'a', 'b', 'c'});
  });

  testWidgets('the long press that starts picking closes the keyboard', (
    tester,
  ) async {
    await pump(tester, results: songs);
    await tester.showKeyboard(find.byType(TextField));
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.longPress(find.text('Title b'));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('a new search lets the songs go', (tester) async {
    await pump(tester, results: songs);
    await tester.longPress(find.text('Title b'));
    await tester.pumpAndSettle();
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    search.emit(SearchLoading());
    // The state reaches the page through the bloc's stream, after a frame.
    await tester.pump();
    await tester.pump();
    expect(selection.state.active, isFalse);
  });
}
