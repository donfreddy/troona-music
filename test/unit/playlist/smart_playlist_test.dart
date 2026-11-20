import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/history/domain/entities/track_stats.dart';
import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/entities/smart_rules.dart';
import 'package:troona/features/playlist/domain/services/smart_playlist.dart';

const today = 20000;

Track _track(
  String id, {
  String? title,
  String artist = 'Artist',
  String album = 'Album',
  String? genre,
  int? year,
  int seconds = 200,
  String ext = 'mp3',
  int? addedDaysAgo,
}) => Track(
  id: id,
  title: title ?? 'Song $id',
  artist: artist,
  artistId: 1,
  album: album,
  albumId: 1,
  genre: genre,
  year: year,
  path: '/music/$id.$ext',
  uri: 'content://$id',
  size: 1,
  durationMs: seconds * 1000,
  fileName: '$id.$ext',
  dateAdded: addedDaysAgo == null
      ? null
      : ListeningDay.date(today - addedDaysAgo).add(const Duration(hours: 12)),
);

void main() {
  List<String> run(
    SmartRules rules,
    List<Track> library, {
    TrackStats? stats,
    Set<String> liked = const {},
    int seed = 0,
  }) => [
    for (final t in SmartPlaylist.evaluate(
      rules,
      library,
      stats: stats ?? TrackStats.empty,
      liked: liked,
      today: today,
      seed: seed,
    ))
      t.id,
  ];

  List<String> keep(
    SmartRule rule,
    List<Track> library, {
    TrackStats? stats,
    Set<String> liked = const {},
  }) => run(
    SmartRules(rules: [rule]),
    library,
    stats: stats,
    liked: liked,
  )..sort();

  group('TrackStats', () {
    final stats = TrackStats({
      'a': [(today, 2), (today - 10, 3), (today - 40, 1)],
    });

    test('plays in a span, both ends included', () {
      expect(stats.playsBetween('a', today - 10, today), 5);
      expect(stats.playsBetween('a', today - 9, today), 2);
      expect(stats.playsBetween('b', 0, today), 0);
    });

    test('total and last day; never played gives 0 and null', () {
      expect(stats.total('a'), 6);
      expect(stats.lastDay('a'), today);
      expect(stats.total('b'), 0);
      expect(stats.lastDay('b'), isNull);
    });
  });

  group('each rule', () {
    final library = [_track('a'), _track('b'), _track('c')];

    test('plays in a period: at least, at most (never played is 0)', () {
      final stats = TrackStats({
        'a': [(today, 5)],
        'b': [(today - 30, 5)],
      });
      const atLeast = PlaysInPeriod(days: 30, count: 5);
      expect(keep(atLeast, library, stats: stats), ['a']);
      // Day today - 29 is the first of 30 days; today - 30 is out.
      const atMost = PlaysInPeriod(days: 30, atLeast: false, count: 0);
      expect(keep(atMost, library, stats: stats), ['b', 'c']);
    });

    test('last played: older than, within, never', () {
      final stats = TrackStats({
        'a': [(today - 90, 1)],
        'b': [(today - 89, 1)],
      });
      expect(
        keep(
          const LastPlayed(LastPlayedKind.olderThan, days: 90),
          library,
          stats: stats,
        ),
        ['a'],
      );
      expect(
        keep(
          const LastPlayed(LastPlayedKind.within, days: 90),
          library,
          stats: stats,
        ),
        ['b'],
      );
      expect(
        keep(const LastPlayed(LastPlayedKind.never), library, stats: stats),
        ['c'],
      );
    });

    test('added within: today counts, no date added does not pass', () {
      final added = [
        _track('a', addedDaysAgo: 0),
        _track('b', addedDaysAgo: 29),
        _track('c', addedDaysAgo: 30),
        _track('d'),
      ];
      expect(keep(const AddedWithin(30), added), ['a', 'b']);
    });

    test('liked or not', () {
      expect(keep(const Liked(true), library, liked: {'b'}), ['b']);
      expect(keep(const Liked(false), library, liked: {'b'}), ['a', 'c']);
    });

    test('text: case and accents ignored, no genre contains nothing', () {
      final songs = [
        _track('a', artist: 'Beyoncé', genre: 'R&B'),
        _track('b', artist: 'BEYONCE, Jay-Z'),
        _track('c', artist: 'Drake'),
      ];
      expect(keep(const TextMatches(SmartTextField.artist, 'beyonce'), songs), [
        'a',
        'b',
      ]);
      expect(
        keep(
          const TextMatches(SmartTextField.artist, 'beyoncé', contains: false),
          songs,
        ),
        ['c'],
      );
      expect(keep(const TextMatches(SmartTextField.genre, 'r&b'), songs), [
        'a',
      ]);
      expect(
        keep(
          const TextMatches(SmartTextField.genre, 'r&b', contains: false),
          songs,
        ),
        ['b', 'c'],
      );
    });

    test('year: both ends included, open ends, no year does not pass', () {
      final songs = [
        _track('a', year: 1999),
        _track('b', year: 2005),
        _track('c', year: 2010),
        _track('d'),
      ];
      expect(keep(const YearBetween(from: 2000, to: 2010), songs), ['b', 'c']);
      expect(keep(const YearBetween(to: 2004), songs), ['a']);
      expect(keep(const YearBetween(from: 2006), songs), ['c']);
    });

    test('duration: both ends included', () {
      final songs = [
        _track('a', seconds: 59),
        _track('b', seconds: 60),
        _track('c', seconds: 600),
      ];
      expect(
        keep(
          const DurationBetween(
            min: Duration(minutes: 1),
            max: Duration(minutes: 10),
          ),
          songs,
        ),
        ['b', 'c'],
      );
    });

    test('lossless: FLAC and WAV, never M4A', () {
      final songs = [
        _track('a', ext: 'flac'),
        _track('b', ext: 'wav'),
        _track('c', ext: 'm4a'),
      ];
      expect(keep(const Lossless(true), songs), ['a', 'b']);
      expect(keep(const Lossless(false), songs), ['c']);
    });
  });

  group('combining', () {
    final library = [
      _track('a', year: 2000),
      _track('b', year: 2020),
      _track('c'),
    ];
    const rules = [YearBetween(from: 2010), Liked(true)];

    test('every rule, or at least one', () {
      expect(run(const SmartRules(rules: rules), library, liked: {'a', 'b'}), [
        'b',
      ]);
      expect(
        run(
          const SmartRules(matchAll: false, rules: rules),
          library,
          liked: {'a'},
        ),
        ['a', 'b'],
      );
    });

    test('no rules keep every song', () {
      expect(run(const SmartRules(), library), ['a', 'b', 'c']);
      expect(run(const SmartRules(matchAll: false), library), ['a', 'b', 'c']);
    });

    test('an empty library or no history keeps nothing, without error', () {
      expect(
        run(const SmartRules(rules: [PlaysInPeriod(days: 7, count: 1)]), []),
        isEmpty,
      );
      expect(
        run(
          const SmartRules(rules: [PlaysInPeriod(days: 7, count: 1)]),
          library,
        ),
        isEmpty,
      );
    });
  });

  group('sorting and the limit', () {
    final library = [
      _track('a', title: 'Charlie', year: 2001, addedDaysAgo: 3),
      _track('b', title: 'alpha', year: 2010, addedDaysAgo: 1),
      _track('c', title: 'Bravo', addedDaysAgo: 2),
      _track('d', title: 'Bravo'),
    ];
    final stats = TrackStats({
      'a': [(today - 1, 3)],
      'b': [(today - 50, 9)],
      'c': [(today, 1)],
    });

    List<String> sorted(SmartSort sort, {int? limit}) => run(
      SmartRules(sort: sort, limit: limit),
      library,
      stats: stats,
    );

    test('title ignores case; a tie breaks on the id', () {
      expect(sorted(SmartSort.title), ['b', 'c', 'd', 'a']);
    });

    test('year newest first, no year last', () {
      expect(sorted(SmartSort.year), ['b', 'a', 'c', 'd']);
    });

    test('added newest and oldest, no date last either way', () {
      expect(sorted(SmartSort.addedNewest), ['b', 'c', 'a', 'd']);
      expect(sorted(SmartSort.addedOldest), ['a', 'c', 'b', 'd']);
    });

    test('plays all time, most and least', () {
      expect(sorted(SmartSort.mostPlayed), ['b', 'a', 'c', 'd']);
      expect(sorted(SmartSort.leastPlayed), ['d', 'c', 'a', 'b']);
    });

    test('last played: never played is the oldest, and last when recent', () {
      expect(sorted(SmartSort.lastPlayedRecent), ['c', 'a', 'b', 'd']);
      expect(sorted(SmartSort.lastPlayedOldest), ['d', 'b', 'a', 'c']);
    });

    test('random: the same seed, the same order, whatever the input order', () {
      final first = sorted(SmartSort.random);
      expect(sorted(SmartSort.random), first);
      final reversed = run(
        const SmartRules(sort: SmartSort.random),
        library.reversed.toList(),
        stats: stats,
      );
      expect(reversed, first);
      expect(first.toSet(), {'a', 'b', 'c', 'd'});
    });

    test('a limit cuts after sorting; one larger than the list keeps all', () {
      expect(sorted(SmartSort.mostPlayed, limit: 2), ['b', 'a']);
      expect(sorted(SmartSort.title, limit: 50), hasLength(4));
      expect(sorted(SmartSort.title, limit: 0), isEmpty);
    });
  });
}
