import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/history/domain/entities/weekly_recap.dart';
import 'package:troona/features/history/domain/repositories/play_history_repository.dart';
import 'package:troona/features/history/domain/use_cases/get_listening_calendar_use_case.dart';
import 'package:troona/features/history/domain/use_cases/get_weekly_recap_use_case.dart';
import 'package:troona/features/history/presentation/cubit/weekly_recap_cubit.dart';
import 'package:troona/features/history/presentation/pages/weekly_recap_page.dart';
import 'package:troona/features/history/presentation/widgets/listening_calendar.dart';
import 'package:troona/features/history/presentation/widgets/weekly_recap_card.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_by_ids_use_case.dart';
import 'package:troona/l10n/app_localizations.dart';

import '../../helpers/fake_player.dart';

Widget _app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  theme: AppTheme.dark,
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

/// Serves a fixed state; [load] does nothing.
class _FixedRecapCubit extends WeeklyRecapCubit {
  _FixedRecapCubit(WeeklyRecapState state)
    : super(
        recap: GetWeeklyRecapUseCase(_NoHistory(), _noTracks),
        calendar: GetListeningCalendarUseCase(_NoHistory()),
      ) {
    emit(state);
  }

  @override
  Future<void> load() async {}
}

final class _NoHistory implements PlayHistoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _noTracks = GetTracksByIdsUseCase(_NoLibrary());

class _NoLibrary extends Fake implements LibraryRepository {}

void main() {
  final song = testTrack('s1', durationMs: 200000)
    ..title = 'One More Time'
    ..artist = 'Daft Punk';

  final recap = WeeklyRecap(
    weekStart: DateTime(2026, 10, 19),
    plays: 42,
    listened: const Duration(hours: 2, minutes: 40),
    topTrack: song,
    topTrackPlays: 7,
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
      final rebuilt = WeeklyRecap(
        weekStart: recap.weekStart,
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
    testWidgets('one dot per day, filled days announced', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          ListeningCalendar(
            month: DateTime(2026, 10),
            activeDays: const {1, 15},
            today: DateTime(2026, 10, 20),
          ),
        ),
      );

      expect(find.text('October 2026'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'music played$')), findsNWidgets(2));
      expect(find.bySemanticsLabel(RegExp(r'no music$')), findsNWidgets(29));
      expect(find.bySemanticsLabel('October 15, music played'), findsOneWidget);
      handle.dispose();
    });
  });

  group('page', () {
    Future<void> pumpPage(WidgetTester tester, WeeklyRecapState state) =>
        tester.pumpWidget(
          _app(
            BlocProvider<WeeklyRecapCubit>(
              create: (_) => _FixedRecapCubit(state),
              child: const WeeklyRecapPage(),
            ),
          ),
        );

    testWidgets('shows the week and the month', (tester) async {
      await pumpPage(
        tester,
        WeeklyRecapState(
          loading: false,
          month: DateTime(2026, 10),
          recap: recap,
          activeDays: const {19, 20},
        ),
      );

      expect(find.text('2 h 40 min'), findsOneWidget);
      expect(find.text('Top song'), findsOneWidget);
      expect(find.text('One More Time'), findsOneWidget);
      expect(find.text('Top artist'), findsOneWidget);
      expect(find.text('3 songs heard for the first time'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('October 2026'), 200);
      expect(find.text('October 2026'), findsOneWidget);
    });

    testWidgets('without a recap, still shows the calendar', (tester) async {
      await pumpPage(
        tester,
        WeeklyRecapState(loading: false, month: DateTime(2026, 10)),
      );

      expect(find.text('Nothing was played last week.'), findsOneWidget);
      expect(find.byType(ListeningCalendar), findsOneWidget);
      expect(find.text('Top song'), findsNothing);
    });
  });
}
