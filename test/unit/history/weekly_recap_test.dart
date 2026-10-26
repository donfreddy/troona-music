import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/history/domain/entities/listening_stats.dart';
import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/history/domain/repositories/play_history_repository.dart';
import 'package:troona/features/history/domain/use_cases/get_listening_calendar_use_case.dart';
import 'package:troona/features/history/domain/use_cases/get_weekly_recap_use_case.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_by_ids_use_case.dart';

import '../../helpers/fake_player.dart';

final class _History implements PlayHistoryRepository {
  ListeningStats stats = ListeningStats.empty;
  Set<int> active = const {};
  (int, int)? asked;

  @override
  Future<Either<Failure, ListeningStats>> listeningStats({
    required int firstDay,
    required int lastDay,
  }) async {
    asked = (firstDay, lastDay);
    return right(stats);
  }

  @override
  Future<Either<Failure, Set<int>>> activeDays({
    required int firstDay,
    required int lastDay,
  }) async => right({
    for (final d in active)
      if (d >= firstDay && d <= lastDay) d,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Answers in the asked order, skipping ids not in [tracks].
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

Track _track(String id, String artist) =>
    testTrack(id, durationMs: 180000)..artist = artist;

void main() {
  group('ListeningDay', () {
    test('consecutive dates are consecutive days, DST changes included', () {
      for (final (y, m, d) in [(2026, 3, 29), (2026, 10, 25), (2026, 12, 31)]) {
        final today = ListeningDay.of(DateTime(y, m, d, 12));
        expect(ListeningDay.of(DateTime(y, m, d + 1, 12)), today + 1);
        expect(ListeningDay.of(DateTime(y, m, d)), today);
        expect(ListeningDay.of(DateTime(y, m, d, 23, 59, 59)), today);
      }
    });

    test('date and weekday round trip', () {
      for (var i = 0; i < 400; i++) {
        final date = DateTime(2026, 1, 1 + i);
        final day = ListeningDay.of(date);
        expect(ListeningDay.date(day), date);
        expect(ListeningDay.weekday(day), date.weekday);
      }
    });

    test('a week starts on Monday', () {
      final sunday = ListeningDay.of(DateTime(2026, 10, 25));
      final monday = ListeningDay.of(DateTime(2026, 10, 19));
      expect(ListeningDay.weekStart(sunday), monday);
      expect(ListeningDay.weekStart(monday), monday);
    });
  });

  group('GetWeeklyRecapUseCase', () {
    late _History history;
    late GetWeeklyRecapUseCase recap;
    final now = DateTime(2026, 10, 28, 10); // a Wednesday
    final lastMonday = ListeningDay.of(DateTime(2026, 10, 19));

    final a1 = _track('a1', 'Daft Punk');
    final a2 = _track('a2', 'Daft Punk');
    final b1 = _track('b1', 'Justice');
    final unknown = _track('u1', '<unknown>');

    setUp(() {
      history = _History();
      recap = GetWeeklyRecapUseCase(
        history,
        GetTracksByIdsUseCase(_Library([a1, a2, b1, unknown])),
      );
    });

    ListeningStats stats(Map<String, int> plays, {int? historyStart}) =>
        ListeningStats(
          plays: plays.values.fold(0, (s, p) => s + p),
          listened: const Duration(hours: 2),
          trackPlays: plays,
          discoveries: 4,
          historyStart: historyStart,
        );

    test('reads last week, Monday to Sunday', () async {
      await recap(now: now);
      expect(history.asked, (lastMonday, lastMonday + 6));
    });

    test('nothing played last week: no recap', () async {
      expect((await recap(now: now)).getOrElse(() => null), isNull);
    });

    test('top song and top artist by plays', () async {
      history.stats = stats({'b1': 5, 'a1': 3, 'a2': 3, 'u1': 9});

      final r = (await recap(now: now)).getOrElse(() => null)!;

      expect(r.weekStart, DateTime(2026, 10, 19));
      expect(r.weekEnd, DateTime(2026, 10, 25));
      expect(r.topTrack, unknown, reason: 'the top song keeps any tag');
      expect(r.topTrackPlays, 9);
      // Daft Punk 6 beats Justice 5; untagged files are no artist.
      expect(r.topArtistTrack?.artist, 'Daft Punk');
      expect(r.topArtistPlays, 6);
    });

    test('a removed track is skipped for the top song', () async {
      history.stats = stats({'gone': 10, 'b1': 2});
      final r = (await recap(now: now)).getOrElse(() => null)!;
      expect(r.topTrack, b1);
      expect(r.topTrackPlays, 2);
    });

    test('discoveries only once the history is four weeks older', () async {
      history.stats = stats({'a1': 1}, historyStart: lastMonday - 27);
      expect((await recap(now: now)).getOrElse(() => null)!.discoveries, null);

      history.stats = stats({'a1': 1}, historyStart: lastMonday - 28);
      expect((await recap(now: now)).getOrElse(() => null)!.discoveries, 4);
    });
  });

  test('the calendar lists days of the month', () async {
    final history = _History()
      ..active = {
        ListeningDay.of(DateTime(2026, 9, 30)),
        ListeningDay.of(DateTime(2026, 10, 1)),
        ListeningDay.of(DateTime(2026, 10, 31)),
        ListeningDay.of(DateTime(2026, 11, 1)),
      };

    final days = await GetListeningCalendarUseCase(history)(DateTime(2026, 10));

    expect(days.getOrElse(() => {}), {1, 31});
  });
}
