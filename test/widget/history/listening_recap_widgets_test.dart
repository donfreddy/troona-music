import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/features/history/domain/entities/listening_recap.dart';
import 'package:troona/features/history/domain/entities/listening_stats.dart';
import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/history/domain/repositories/play_history_repository.dart';
import 'package:troona/features/history/domain/services/listening_moments.dart';
import 'package:troona/features/history/domain/use_cases/get_listening_recap_use_case.dart';
import 'package:troona/features/history/presentation/cubit/listening_recap_cubit.dart';
import 'package:troona/features/history/presentation/pages/listening_recap_page.dart';
import 'package:troona/features/history/presentation/widgets/heat_cell.dart';
import 'package:troona/features/history/presentation/widgets/listening_calendar.dart';
import 'package:troona/features/history/presentation/widgets/listening_moments_grid.dart';
import 'package:troona/features/history/presentation/widgets/weekly_recap_card.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_by_ids_use_case.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/l10n/app_localizations.dart';

import '../../helpers/fake_player.dart';

Widget _app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  theme: AppTheme.dark,
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

int _day(int y, int m, int d) => ListeningDay.of(DateTime(y, m, d));

List<int> _hours(Map<(int, int), int> plays) {
  final list = List.filled(7 * 24, 0);
  for (final MapEntry(key: (weekday, hour), value: n) in plays.entries) {
    list[(weekday - 1) * 24 + hour] = n;
  }
  return list;
}

final class _History implements PlayHistoryRepository {
  ListeningStats stats;
  _History(this.stats);

  @override
  Future<Either<Failure, ListeningStats>> listeningStats({
    required int firstDay,
    required int lastDay,
  }) async => right(stats);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Library implements LibraryRepository {
  final Map<String, Track> tracks;
  _Library(List<Track> list) : tracks = {for (final t in list) t.id: t};

  @override
  Future<Either<Failure, List<Track>>> getTracksByIds(List<String> ids) async =>
      right([
        for (final id in ids)
          if (tracks[id] != null) tracks[id]!,
      ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final song = testTrack('s1', durationMs: 200000)
    ..title = 'One More Time'
    ..artist = 'Daft Punk'
    ..album = 'Discovery'
    ..albumId = 10;
  final other = testTrack('s2', durationMs: 200000)
    ..title = 'Genesis'
    ..artist = 'Justice'
    ..album = 'Cross'
    ..albumId = 20;
  final lastMonday = _day(2026, 10, 19);

  final recap = ListeningRecap(
    period: RecapPeriod.week,
    firstDay: lastMonday,
    lastDay: lastMonday + 6,
    plays: 42,
    listened: const Duration(hours: 2, minutes: 40),
    topTracks: [RankedTrack(song, 7)],
    topArtist: song.credits.first,
    topArtistTrack: song,
    topArtistPlays: 12,
    discoveries: 3,
  );

  group('card', () {
    testWidgets('shows listening time and top artist', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(WeeklyRecapCard(recap: recap, onTap: () => taps++)),
      );

      expect(find.text('Your week in music'), findsOneWidget);
      expect(find.text('Oct 19 to Oct 25'), findsOneWidget);
      expect(find.text('2 h 40 min'), findsOneWidget);
      expect(find.text('Daft Punk'), findsOneWidget);

      await tester.tap(find.byType(WeeklyRecapCard));
      expect(taps, 1);
    });

    testWidgets('a week without listening time shows its plays', (
      tester,
    ) async {
      final rebuilt = ListeningRecap(
        period: RecapPeriod.week,
        firstDay: lastMonday,
        lastDay: lastMonday + 6,
        plays: 42,
        listened: Duration.zero,
      );
      await tester.pumpWidget(
        _app(WeeklyRecapCard(recap: rebuilt, onTap: () {})),
      );

      expect(find.text('42 plays'), findsOneWidget);
    });

    testWidgets('reads in French', (tester) async {
      await tester.pumpWidget(
        _app(
          WeeklyRecapCard(recap: recap, onTap: () {}),
          locale: const Locale('fr'),
        ),
      );

      expect(find.text('Votre semaine en musique'), findsOneWidget);
      expect(find.text('Du 19 oct. au 25 oct.'), findsOneWidget);
    });
  });

  group('calendar', () {
    Color fillOf(WidgetTester tester, String label) {
      final cell = find.byWidgetPredicate(
        (w) => w is HeatCell && w.semanticLabel == label,
      );
      final box = tester.widget<DecoratedBox>(
        find.descendant(of: cell, matching: find.byType(DecoratedBox)).first,
      );
      return (box.decoration as BoxDecoration).color!;
    }

    testWidgets('a month: one square per day, filled by its plays', (
      tester,
    ) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(400, 800);
      addTearDown(tester.view.reset);
      final handle = tester.ensureSemantics();
      final oct = _day(2026, 10, 1);
      await tester.pumpWidget(
        _app(
          ListeningCalendar(
            firstDay: oct,
            lastDay: oct + 30,
            dayPlays: {oct: 2, oct + 14: 30},
            today: oct + 19,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HeatCell), findsNWidgets(31));
      expect(
        find.bySemanticsLabel('Thursday, October 15, 30 plays'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Thursday, October 1, 1 play'),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel('Thursday, October 1, 2 plays'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp(r'no music$')), findsNWidgets(29));

      final accent = AppColors.dark.accent;
      expect(fillOf(tester, 'Thursday, October 15, 30 plays'), accent);
      expect(
        fillOf(tester, 'Thursday, October 1, 2 plays').a,
        lessThan(accent.a / 2),
      );
      // Today is ringed.
      final today = tester.widget<HeatCell>(
        find.byWidgetPredicate(
          (w) =>
              w is HeatCell &&
              w.semanticLabel.startsWith('Tuesday, October 20'),
        ),
      );
      expect(today.marked, isTrue);
      expect(find.text('Less'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a week: seven squares in one row', (tester) async {
      await tester.pumpWidget(
        _app(
          ListeningCalendar(
            firstDay: lastMonday,
            lastDay: lastMonday + 6,
            dayPlays: const {},
            today: lastMonday + 10,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cells = find.byType(HeatCell);
      expect(cells, findsNWidgets(7));
      final tops = {
        for (var i = 0; i < 7; i++) tester.getTopLeft(cells.at(i)).dy,
      };
      expect(tops, hasLength(1));
    });

    testWidgets('the squares light up one after the other', (tester) async {
      await tester.pumpWidget(
        _app(
          ListeningCalendar(
            firstDay: lastMonday,
            lastDay: lastMonday + 6,
            dayPlays: const {},
            today: lastMonday,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final opacities = [
        for (final o in tester.widgetList<Opacity>(
          find.ancestor(
            of: find.byType(HeatCell),
            matching: find.byType(Opacity),
          ),
        ))
          o.opacity,
      ];
      expect(opacities.first, greaterThan(opacities.last));
      await tester.pumpAndSettle();
      expect(
        find.ancestor(
          of: find.byType(HeatCell),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
    });

    testWidgets('still when animations are reduced', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _app(
            ListeningCalendar(
              firstDay: lastMonday,
              lastDay: lastMonday + 6,
              dayPlays: const {},
              today: lastMonday,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.ancestor(
          of: find.byType(HeatCell),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
    });
  });

  group('when you listen', () {
    testWidgets('names the peak and fills 28 squares', (tester) async {
      await tester.pumpWidget(
        _app(
          ListeningMomentsGrid(
            moments: ListeningMoments.fromHours(
              _hours({(5, 20): 6, (1, 8): 1}),
            ),
            spanKey: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Peak: Friday evening'), findsOneWidget);
      expect(find.byType(HeatCell), findsNWidgets(28));
      expect(find.text('Morning'), findsOneWidget);
    });

    testWidgets('a night belongs to the evening before', (tester) async {
      final moments = ListeningMoments.fromHours(_hours({(6, 2): 6}));
      await tester.pumpWidget(
        _app(ListeningMomentsGrid(moments: moments, spanKey: 1)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Peak: Friday night'), findsOneWidget);

      await tester.pumpWidget(
        _app(
          ListeningMomentsGrid(moments: moments, spanKey: 1),
          locale: const Locale('fr'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text("Pic d'écoute : la nuit du vendredi au samedi"),
        findsOneWidget,
      );
    });

    testWidgets('without plays: a line, no empty grid', (tester) async {
      await tester.pumpWidget(
        _app(
          const ListeningMomentsGrid(
            moments: ListeningMoments.none,
            spanKey: 1,
          ),
        ),
      );
      expect(find.byType(HeatCell), findsNothing);
      expect(
        find.text('Your listening moments show up as you play music.'),
        findsOneWidget,
      );
    });
  });

  group('page', () {
    final now = DateTime(2026, 10, 28, 10); // a Wednesday

    Future<(ListeningRecapCubit, FakeAudioPort)> open(
      WidgetTester tester, {
      required ListeningStats stats,
      Size size = const Size(400, 2400),
      double textScale = 1,
    }) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final port = FakeAudioPort();
      final player = buildTestPlayerBloc(port, PlaybackSessionStore(prefs));
      final cubit = ListeningRecapCubit(
        recap: GetListeningRecapUseCase(
          _History(stats),
          GetTracksByIdsUseCase(_Library([song, other])),
        ),
        now: () => now,
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        unawaited(cubit.close());
        unawaited(player.close());
        unawaited(port.close());
      });
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<PlayerBloc>.value(value: player),
            BlocProvider<ListeningRecapCubit>.value(value: cubit..load()),
          ],
          child: _app(const ListeningRecapPage()),
        ),
      );
      await tester.pumpAndSettle();
      return (cubit, port);
    }

    final full = ListeningStats(
      plays: 42,
      listened: const Duration(hours: 2, minutes: 40),
      trackPlays: const {'s1': 7, 's2': 3},
      dayPlays: {lastMonday: 30, lastMonday + 4: 12},
      hourPlays: _hours({(5, 20): 9, (1, 8): 2}),
      discoveries: 3,
      historyStart: lastMonday - 60,
    );

    testWidgets('last week: summary, days, tops and moments', (tester) async {
      await open(tester, stats: full);

      expect(find.text('Your listening'), findsWidgets);
      expect(find.text('Last week'), findsOneWidget);
      expect(find.text('Oct 19 to Oct 25'), findsOneWidget);
      expect(find.text('2 h 40 min'), findsOneWidget);
      expect(
        find.text('listened • 42 plays • 2 days with music'),
        findsOneWidget,
      );
      expect(find.text('IN PROGRESS'), findsNothing);
      expect(find.byType(HeatCell), findsNWidgets(7 + 28));
      expect(
        find.text('Busiest day: Monday, October 19, 30 plays'),
        findsOneWidget,
      );
      expect(find.text('Top songs'), findsOneWidget);
      expect(find.text('One More Time'), findsWidgets);
      expect(find.text('Genesis'), findsOneWidget);
      expect(find.text('Top albums'), findsOneWidget);
      expect(find.text('Discovery'), findsOneWidget);
      expect(find.text('Peak: Friday evening'), findsOneWidget);
      expect(find.text('3 songs heard for the first time'), findsOneWidget);
    });

    testWidgets('a top song plays the list from it', (tester) async {
      final (_, port) = await open(tester, stats: full);

      await tester.tap(find.text('Genesis'));
      await tester.pumpAndSettle();

      final set = port.lastSetQueue!;
      expect(set.tracks.map((t) => t.id), ['s1', 's2']);
      expect(set.startIndex, 1);
    });

    testWidgets('Month shows this month, in progress', (tester) async {
      final (cubit, _) = await open(tester, stats: full);

      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();

      expect(cubit.state.period, RecapPeriod.month);
      expect(find.text('This month'), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('IN PROGRESS'), findsOneWidget);
      expect(find.byType(HeatCell), findsNWidgets(31 + 28));
    });

    testWidgets('the arrows move between weeks, not past this one', (
      tester,
    ) async {
      final (cubit, _) = await open(tester, stats: full);

      await tester.tap(find.byTooltip('Later'));
      await tester.pumpAndSettle();
      expect(find.text('This week'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byTooltip('Later'),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(find.byTooltip('Earlier'));
      await tester.tap(find.byTooltip('Earlier'));
      await tester.pumpAndSettle();
      expect(cubit.state.firstDay, lastMonday - 7);
      expect(find.text('Oct 12 to Oct 18'), findsOneWidget);
    });

    testWidgets('a span without plays says so', (tester) async {
      await open(
        tester,
        stats: const ListeningStats(
          plays: 0,
          listened: Duration.zero,
          trackPlays: {},
          discoveries: 0,
          historyStart: null,
        ),
      );

      expect(find.text('Nothing was played.'), findsOneWidget);
      expect(find.byType(HeatCell), findsNWidgets(7));
      expect(find.text('Top songs'), findsNothing);
      expect(find.text('When you listen'), findsNothing);
    });

    for (final scale in [1.0, 1.3, 2.0]) {
      for (final period in RecapPeriod.values) {
        testWidgets('360 x 640, text x$scale, ${period.name}: no overflow', (
          tester,
        ) async {
          final (cubit, _) = await open(
            tester,
            stats: full,
            size: const Size(360, 640),
            textScale: scale,
          );
          await cubit.showPeriod(period);
          await tester.pumpAndSettle();
          // Every section, built as it scrolls in.
          for (var i = 0; i < 12; i++) {
            await tester.drag(
              find.byType(CustomScrollView),
              const Offset(0, -300),
            );
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
