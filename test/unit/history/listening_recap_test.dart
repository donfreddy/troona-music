import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/history/domain/entities/listening_recap.dart';
import 'package:troona/features/history/domain/entities/listening_stats.dart';
import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/history/domain/repositories/play_history_repository.dart';
import 'package:troona/features/history/domain/services/listening_moments.dart';
import 'package:troona/features/history/domain/services/play_intensity.dart';
import 'package:troona/features/history/domain/use_cases/get_listening_recap_use_case.dart';
import 'package:troona/features/history/presentation/cubit/listening_recap_cubit.dart';
import 'package:troona/features/library/domain/entities/artist_credit.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/services/track_tags.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_by_ids_use_case.dart';

final class _History implements PlayHistoryRepository {
  ListeningStats stats = ListeningStats.empty;
  bool fail = false;
  final asked = <(int, int)>[];

  /// When set, each read waits for its own completer, in order.
  List<Completer<void>>? gates;

  @override
  Future<Either<Failure, ListeningStats>> listeningStats({
    required int firstDay,
    required int lastDay,
  }) async {
    final read = asked.length;
    asked.add((firstDay, lastDay));
    final gates = this.gates;
    if (gates != null) await gates[read].future;
    if (fail) return left(const DatabaseFailure());
    return right(stats);
  }

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

Track _track(
  String id,
  String artist, {
  List<String>? credits,
  String album = 'Album',
  int albumId = 1,
  String? artwork,
}) => Track(
  id: id,
  title: id,
  artist: artist,
  artistId: TrackTags.artistIdFor(artist),
  credits: [
    for (final name in credits ?? [artist])
      ArtistCredit(id: TrackTags.artistIdFor(name), name: name),
  ],
  album: album,
  albumId: albumId,
  path: '/$id.mp3',
  uri: '',
  size: 0,
  durationMs: 180000,
  fileName: '$id.mp3',
  artworkPath: artwork,
);

int _day(int y, int m, int d) => ListeningDay.of(DateTime(y, m, d));

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

  group('RecapPeriod', () {
    test('a week runs Monday to Sunday', () {
      final wednesday = _day(2026, 10, 28);
      expect(RecapPeriod.week.rangeOf(wednesday), (
        _day(2026, 10, 26),
        _day(2026, 11, 1),
      ));
    });

    test('a month runs from its first to its last day', () {
      expect(RecapPeriod.month.rangeOf(_day(2026, 10, 15)), (
        _day(2026, 10, 1),
        _day(2026, 10, 31),
      ));
      expect(RecapPeriod.month.rangeOf(_day(2028, 2, 29)), (
        _day(2028, 2, 1),
        _day(2028, 2, 29),
      ));
    });

    test('shifts by whole spans, across the new year', () {
      final monday = _day(2026, 10, 26);
      expect(RecapPeriod.week.shift(monday, -1), _day(2026, 10, 19));
      expect(RecapPeriod.week.shift(monday, 2), _day(2026, 11, 9));
      expect(RecapPeriod.month.shift(_day(2026, 1, 1), -1), _day(2025, 12, 1));
      expect(RecapPeriod.month.shift(_day(2026, 12, 1), 1), _day(2027, 1, 1));
    });
  });

  group('PlayIntensity', () {
    test('fixed steps of plays', () {
      final levels = {
        0: 0,
        1: 1,
        4: 1,
        5: 2,
        14: 2,
        15: 3,
        29: 3,
        30: 4,
        400: 4,
      };
      for (final MapEntry(key: plays, value: level) in levels.entries) {
        expect(PlayIntensity.levelOf(plays), level, reason: '$plays plays');
      }
    });

    test('relative steps against the largest', () {
      expect(PlayIntensity.relativeLevelOf(0, 10), 0);
      expect(PlayIntensity.relativeLevelOf(1, 10), 1);
      expect(PlayIntensity.relativeLevelOf(5, 10), 2);
      expect(PlayIntensity.relativeLevelOf(6, 10), 3);
      expect(PlayIntensity.relativeLevelOf(10, 10), 4);
      expect(PlayIntensity.relativeLevelOf(3, 0), 0);
      expect(PlayIntensity.relativeLevelOf(21 / 5, 28 / 5), 3);
    });
  });

  group('ListeningMoments', () {
    List<int> hours(Map<(int, int), int> plays) {
      final list = List.filled(7 * 24, 0);
      for (final MapEntry(key: (weekday, hour), value: n) in plays.entries) {
        list[(weekday - 1) * 24 + hour] = n;
      }
      return list;
    }

    test('hours fall in their quarter of the day', () {
      final m = ListeningMoments.fromHours(
        hours({(1, 6): 2, (1, 11): 3, (1, 12): 4, (7, 23): 5}),
      );
      expect(m.playsAt(1, DayPart.morning), 5);
      expect(m.playsAt(1, DayPart.afternoon), 4);
      expect(m.playsAt(7, DayPart.evening), 5);
      expect(m.playsAt(2, DayPart.evening), 0);
      expect(m.total, 14);
      expect(m.maxRate, 5);
    });

    test('a night belongs to the evening before', () {
      final m = ListeningMoments.fromHours(
        hours({(6, 2): 3, (1, 5): 1, (1, 6): 1}),
      );
      expect(m.playsAt(5, DayPart.night), 3, reason: 'Saturday 2:00');
      expect(m.playsAt(7, DayPart.night), 1, reason: 'Monday 5:00');
      expect(m.playsAt(6, DayPart.night), 0);
      expect(m.playsAt(1, DayPart.morning), 1);
    });

    test('a weekday held five times weighs as one held four', () {
      // October 2026: five Thursdays, four Fridays.
      final counts = [4, 4, 4, 5, 5, 5, 4];
      final m = ListeningMoments.fromHours(
        hours({(4, 20): 10, (5, 20): 9}),
        weekdayCounts: counts,
      );
      expect(m.rateAt(4, DayPart.evening), 2);
      expect(m.rateAt(5, DayPart.evening), 9 / 5);
      // A Thursday night falls on Fridays.
      final nights = ListeningMoments.fromHours(
        hours({(5, 1): 10}),
        weekdayCounts: counts,
      );
      expect(nights.rateAt(4, DayPart.night), 2);

      final habits = ListeningMoments.fromHours(
        hours({(4, 20): 10, (1, 20): 9}),
        weekdayCounts: counts,
      );
      expect(habits.peak, (1, DayPart.evening), reason: '9 / 4 beats 10 / 5');
    });

    test('no plays: empty', () {
      expect(ListeningMoments.fromHours(List.filled(168, 0)).isEmpty, isTrue);
      expect(ListeningMoments.fromHours(const []).isEmpty, isTrue);
    });

    test('a peak needs enough plays and a clear first', () {
      expect(ListeningMoments.fromHours(hours({(5, 20): 4})).peak, isNull);
      expect(ListeningMoments.fromHours(hours({(5, 20): 5})).peak, (
        5,
        DayPart.evening,
      ));
      expect(
        ListeningMoments.fromHours(hours({(5, 20): 3, (6, 9): 3})).peak,
        isNull,
        reason: 'a tie for first is no peak',
      );
    });
  });

  test('the busiest day is the earliest of the most played', () {
    final recap = ListeningRecap(
      period: RecapPeriod.week,
      firstDay: 10,
      lastDay: 16,
      plays: 9,
      listened: Duration.zero,
      dayPlays: const {14: 4, 11: 4, 12: 1},
    );
    expect(recap.busiestDay?.key, 11);
    expect(recap.activeDays, 3);
  });

  group('GetListeningRecapUseCase', () {
    late _History history;
    late GetListeningRecapUseCase recap;
    final lastMonday = _day(2026, 10, 19);

    final a1 = _track('a1', 'Daft Punk', album: 'Discovery', albumId: 10);
    final a2 = _track(
      'a2',
      'Daft Punk',
      album: 'Discovery',
      albumId: 10,
      artwork: '/a2.jpg',
    );
    final b1 = _track('b1', 'Justice', album: 'Cross', albumId: 20);
    final unknown = _track('u1', '<unknown>', album: '<unknown>', albumId: 30);
    final collab = _track(
      'c1',
      'Justice, Daft Punk',
      credits: ['Justice', 'Daft Punk'],
      album: '',
      albumId: 40,
    );
    final extra = [
      for (var i = 0; i < 6; i++)
        _track('x$i', 'Air', album: 'Moon $i', albumId: 100 + i),
    ];

    setUp(() {
      history = _History();
      recap = GetListeningRecapUseCase(
        history,
        GetTracksByIdsUseCase(
          _Library([a1, a2, b1, unknown, collab, ...extra]),
        ),
      );
    });

    ListeningStats stats(Map<String, int> plays, {int? historyStart}) =>
        ListeningStats(
          plays: plays.values.fold(0, (s, p) => s + p),
          listened: const Duration(hours: 2),
          trackPlays: plays,
          dayPlays: {lastMonday: 3},
          hourPlays: [for (var i = 0; i < 168; i++) i == 20 ? 7 : 0],
          discoveries: 4,
          historyStart: historyStart,
        );

    // Long after every span read here.
    final later = _day(2027, 1, 1);

    Future<ListeningRecap> week(int day) async => (await recap(
      RecapPeriod.week,
      day,
      today: later,
    )).getOrElse(() => throw 'failed');

    test('a month counts each of its weekdays', () async {
      history.stats = stats({'a1': 1});
      final r = (await recap(
        RecapPeriod.month,
        _day(2026, 10, 9),
        today: later,
      )).getOrElse(() => throw 'failed');
      // Monday 20:00 played 7 times; October 2026 holds four Mondays.
      expect(r.moments.rateAt(1, DayPart.evening), 7 / 4);
    });

    test('a month in progress counts only the days lived', () async {
      history.stats = ListeningStats(
        plays: 19,
        listened: Duration.zero,
        trackPlays: const {'a1': 19},
        hourPlays: [
          for (var i = 0; i < 168; i++)
            i == 6 * 24 + 20
                ? 10 // Sunday evening
                : i == 1 * 24 + 20
                ? 9 // Tuesday evening
                : 0,
        ],
        discoveries: 0,
        historyStart: 0,
      );
      // Wednesday, November 4, 2026: one Sunday and one Tuesday lived,
      // though the month holds five Sundays and four Tuesdays.
      final r = (await recap(
        RecapPeriod.month,
        _day(2026, 11, 4),
        today: _day(2026, 11, 4),
      )).getOrElse(() => throw 'failed');
      expect(r.moments.rateAt(7, DayPart.evening), 10);
      expect(r.moments.rateAt(2, DayPart.evening), 9);
      expect(r.moments.peak, (7, DayPart.evening));
    });

    test('a month the history began in counts from its start', () async {
      history.stats = ListeningStats(
        plays: 4,
        listened: Duration.zero,
        trackPlays: const {'a1': 4},
        hourPlays: [for (var i = 0; i < 168; i++) i == 20 ? 4 : 0],
        discoveries: 0,
        historyStart: _day(2026, 10, 20), // a Tuesday
      );
      final r = (await recap(
        RecapPeriod.month,
        _day(2026, 10, 9),
        today: later,
      )).getOrElse(() => throw 'failed');
      // Mondays from October 20: the 26th only.
      expect(r.moments.rateAt(1, DayPart.evening), 4);
    });

    test('reads the span of the day', () async {
      await recap(RecapPeriod.month, _day(2026, 10, 9), today: later);
      await recap(RecapPeriod.week, lastMonday + 3, today: later);
      expect(history.asked, [
        (_day(2026, 10, 1), _day(2026, 10, 31)),
        (lastMonday, lastMonday + 6),
      ]);
    });

    test('nothing played: the span with zeros', () async {
      history.stats = const ListeningStats(
        plays: 0,
        listened: Duration.zero,
        trackPlays: {},
        discoveries: 0,
        historyStart: 5,
      );
      final r = await week(lastMonday);
      expect(r.plays, 0);
      expect(r.start, DateTime(2026, 10, 19));
      expect(r.end, DateTime(2026, 10, 25));
      expect(r.topTracks, isEmpty);
      expect(r.historyStart, 5);
    });

    test('top songs, artist, days and moments', () async {
      history.stats = stats({'b1': 5, 'a1': 3, 'a2': 3, 'u1': 9});

      final r = await week(lastMonday);

      expect(r.topTrack, unknown, reason: 'the top song keeps any tag');
      expect(r.topTrackPlays, 9);
      expect(
        [for (final t in r.topTracks) t.track.id],
        ['u1', 'b1', 'a1', 'a2'],
      );
      // Daft Punk 6 beats Justice 5; untagged files are no artist.
      expect(r.topArtist?.name, 'Daft Punk');
      expect(r.topArtistTrack?.artist, 'Daft Punk');
      expect(r.topArtistPlays, 6);
      expect(r.dayPlays, {lastMonday: 3});
      expect(r.moments.playsAt(1, DayPart.evening), 7);
    });

    test('at most five songs and five albums', () async {
      history.stats = stats({for (var i = 0; i < 6; i++) 'x$i': 10 - i});
      final r = await week(lastMonday);
      expect(r.topTracks, hasLength(5));
      expect(r.topTracks.last.track.id, 'x4');
      expect([for (final a in r.topAlbums) a.id], [100, 101, 102, 103, 104]);
    });

    test('albums add up their songs; no name, no album', () async {
      history.stats = stats({'b1': 5, 'a1': 3, 'a2': 3, 'u1': 9, 'c1': 20});

      final r = await week(lastMonday);

      expect(
        [for (final a in r.topAlbums) (a.id, a.name, a.plays)],
        [(10, 'Discovery', 6), (20, 'Cross', 5)],
      );
      expect(
        r.topAlbums.first.cover,
        a2,
        reason: 'the most played song with a cover',
      );
    });

    test('an album without any cover shows its top song', () async {
      history.stats = stats({'a1': 3});
      expect((await week(lastMonday)).topAlbums.single.cover, a1);
    });

    test('albums tied on plays: the one with the top song first', () async {
      history.stats = stats({'b1': 6, 'a1': 3, 'a2': 3});
      final r = await week(lastMonday);
      expect([for (final a in r.topAlbums) a.id], [20, 10]);
    });

    test('a collaboration counts for each of its artists', () async {
      history.stats = stats({'b1': 5, 'a1': 3, 'c1': 4});

      final r = await week(lastMonday);

      // Justice 5 + 4 beats Daft Punk 3 + 4.
      expect(r.topArtist?.name, 'Justice');
      expect(r.topArtistPlays, 9);
    });

    test('a removed track is skipped', () async {
      history.stats = stats({'gone': 10, 'b1': 2});
      final r = await week(lastMonday);
      expect(r.topTrack, b1);
      expect(r.topTrackPlays, 2);
    });

    test('discoveries only once the history is four weeks older', () async {
      history.stats = stats({'a1': 1}, historyStart: lastMonday - 27);
      expect((await week(lastMonday)).discoveries, null);

      history.stats = stats({'a1': 1}, historyStart: lastMonday - 28);
      expect((await week(lastMonday)).discoveries, 4);
    });
  });

  group('ListeningRecapCubit', () {
    final now = DateTime(2026, 10, 28, 10); // a Wednesday
    final today = _day(2026, 10, 28);
    final thisMonday = _day(2026, 10, 26);
    final a1 = _track('a1', 'Daft Punk');

    ListeningRecapCubit cubitOn(_History history) => ListeningRecapCubit(
      recap: GetListeningRecapUseCase(
        history,
        GetTracksByIdsUseCase(_Library([a1])),
      ),
      now: () => now,
    );

    _History playedSince(int historyStart) =>
        _History()
          ..stats = ListeningStats(
            plays: 3,
            listened: const Duration(minutes: 9),
            trackPlays: const {'a1': 3},
            discoveries: 1,
            historyStart: historyStart,
          );

    test('opens on last week', () async {
      final history = playedSince(0);
      final cubit = cubitOn(history);
      addTearDown(cubit.close);

      expect(cubit.state.loading, isTrue);
      expect(cubit.state.firstDay, thisMonday - 7);
      await cubit.load();

      expect(cubit.state.loading, isFalse);
      expect(cubit.state.isPrevious, isTrue);
      expect(cubit.state.isCurrent, isFalse);
      expect(cubit.state.recap?.topTrack, a1);
      expect(history.asked.single, (thisMonday - 7, thisMonday - 1));
    });

    test('the month opens on this month', () async {
      final history = playedSince(0);
      final cubit = cubitOn(history);
      addTearDown(cubit.close);

      await cubit.showPeriod(RecapPeriod.month);

      expect(cubit.state.period, RecapPeriod.month);
      expect(cubit.state.firstDay, _day(2026, 10, 1));
      expect(cubit.state.isCurrent, isTrue);
      expect(cubit.state.recap?.period, RecapPeriod.month);
    });

    test('moves between spans, never past today', () async {
      final cubit = cubitOn(playedSince(0));
      addTearDown(cubit.close);
      await cubit.load();

      await cubit.step(1);
      expect(cubit.state.firstDay, thisMonday);
      expect(cubit.state.isCurrent, isTrue);
      expect(cubit.state.canGoForward, isFalse);

      await cubit.step(1);
      expect(cubit.state.firstDay, thisMonday, reason: 'no week after today');

      await cubit.step(-3);
      expect(cubit.state.firstDay, thisMonday - 21);
      expect(cubit.state.today, today);
    });

    test('no going back before the history began', () async {
      final cubit = cubitOn(playedSince(thisMonday - 9));
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.canGoBack, isTrue, reason: 'it began the week before');

      await cubit.step(-1);
      expect(cubit.state.canGoBack, isFalse);
    });

    test('a slow answer for a span already left is dropped', () async {
      final history = playedSince(0)
        ..gates = [Completer<void>(), Completer<void>()];
      final cubit = cubitOn(history);
      addTearDown(cubit.close);

      final first = cubit.load();
      final second = cubit.showPeriod(RecapPeriod.month);
      history.gates![1].complete();
      await second;
      expect(cubit.state.recap?.period, RecapPeriod.month);

      history.gates![0].complete();
      await first;
      expect(cubit.state.recap?.period, RecapPeriod.month);
      expect(cubit.state.period, RecapPeriod.month);
    });

    test('load follows the clock: last week moves on on Monday', () async {
      var clock = DateTime(2026, 11, 1, 22); // a Sunday
      final cubit = ListeningRecapCubit(
        recap: GetListeningRecapUseCase(
          playedSince(0),
          GetTracksByIdsUseCase(_Library([a1])),
        ),
        now: () => clock,
      );
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.firstDay, _day(2026, 10, 19));

      clock = DateTime(2026, 11, 2, 8); // Monday
      await cubit.load();
      expect(cubit.state.firstDay, _day(2026, 10, 26));
      expect(cubit.state.today, _day(2026, 11, 2));
    });

    test('a failed read keeps the way back', () async {
      final history = playedSince(0);
      final cubit = cubitOn(history);
      addTearDown(cubit.close);
      await cubit.load();

      history.fail = true;
      await cubit.step(-1);

      expect(cubit.state.recap, isNull);
      expect(cubit.state.failed, isTrue);
      expect(cubit.state.canGoBack, isTrue);
    });

    test('isShown only once the span read is the one named', () async {
      final history = playedSince(0)..gates = [Completer<void>()];
      final cubit = cubitOn(history);
      addTearDown(cubit.close);
      final read = cubit.load();
      expect(cubit.state.isShown, isFalse);
      history.gates![0].complete();
      await read;
      expect(cubit.state.isShown, isTrue);
    });

    test('a new day: the default span moves on, another one stays', () async {
      var clock = DateTime(2026, 11, 1, 22); // a Sunday
      final cubit = ListeningRecapCubit(
        recap: GetListeningRecapUseCase(
          playedSince(0),
          GetTracksByIdsUseCase(_Library([a1])),
        ),
        now: () => clock,
      );
      addTearDown(cubit.close);
      await cubit.load();
      await cubit.refreshClock();
      expect(cubit.state.firstDay, _day(2026, 10, 19), reason: 'same day');

      clock = DateTime(2026, 11, 2, 8); // Monday
      await cubit.refreshClock();
      expect(cubit.state.firstDay, _day(2026, 10, 26));

      // This week, then a new Monday: the week stays, the arrow opens.
      await cubit.step(1);
      expect(cubit.state.isCurrent, isTrue);
      clock = DateTime(2026, 11, 9, 8);
      await cubit.refreshClock();
      expect(cubit.state.firstDay, _day(2026, 11, 2));
      expect(cubit.state.canGoForward, isTrue);
    });

    test('a failed read shows no recap, not an error', () async {
      final cubit = cubitOn(_History()..fail = true);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.loading, isFalse);
      expect(cubit.state.recap, isNull);
    });
  });
}
