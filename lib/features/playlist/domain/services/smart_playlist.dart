import 'dart:math' as math;

import 'package:troona/core/utils/sort_key.dart';
import 'package:troona/features/history/domain/entities/track_stats.dart';
import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/library/domain/entities/audio_format.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/entities/smart_rules.dart';

/// Works out a smart playlist's songs.
abstract final class SmartPlaylist {
  /// The songs of [library] that [rules] keep, sorted and cut to the limit.
  ///
  /// [stats] holds every song's plays, [liked] the ids of the liked songs,
  /// [today] is a `ListeningDay` key. [seed] orders [SmartSort.random]: the
  /// same seed, the same order, so a page keeps its order while it is open.
  static List<Track> evaluate(
    SmartRules rules,
    List<Track> library, {
    required TrackStats stats,
    required Set<String> liked,
    required int today,
    int seed = 0,
  }) {
    final context = _Context(stats, liked, today);
    final kept = [
      for (final track in library)
        if (_keeps(rules, track, context)) track,
    ];
    _sort(kept, rules.sort, context, seed);
    final limit = rules.limit;
    return limit == null || limit >= kept.length
        ? kept
        : kept.sublist(0, math.max(limit, 0));
  }

  static bool _keeps(SmartRules rules, Track track, _Context context) {
    if (rules.rules.isEmpty) return true;
    return rules.matchAll
        ? rules.rules.every((r) => _passes(r, track, context))
        : rules.rules.any((r) => _passes(r, track, context));
  }

  /// Whether [track] passes [rule].
  static bool _passes(SmartRule rule, Track track, _Context context) {
    final today = context.today;
    return switch (rule) {
      PlaysInPeriod(:final days, :final atLeast, :final count) => () {
        final plays = context.stats.playsBetween(
          track.id,
          today - days + 1,
          today,
        );
        return atLeast ? plays >= count : plays <= count;
      }(),
      LastPlayed(:final kind, :final days) => switch (kind) {
        LastPlayedKind.never => context.stats.lastDay(track.id) == null,
        LastPlayedKind.within => switch (context.stats.lastDay(track.id)) {
          final last? => last > today - days,
          null => false,
        },
        LastPlayedKind.olderThan => switch (context.stats.lastDay(track.id)) {
          final last? => last <= today - days,
          null => false,
        },
      },
      AddedWithin(:final days) => switch (track.dateAdded) {
        final added? => ListeningDay.of(added) > today - days,
        null => false,
      },
      Liked(:final liked) => context.liked.contains(track.id) == liked,
      TextMatches(:final field, :final text, :final contains) => () {
        final value = switch (field) {
          SmartTextField.artist => track.artist,
          SmartTextField.album => track.album,
          SmartTextField.genre => track.genre ?? '',
        };
        final found = sortKey(value).contains(sortKey(text));
        return found == contains;
      }(),
      YearBetween(:final from, :final to) => switch (track.year) {
        final year? =>
          (from == null || year >= from) && (to == null || year <= to),
        null => false,
      },
      DurationBetween(:final min, :final max) => () {
        final duration = Duration(milliseconds: track.durationMs);
        return (min == null || duration >= min) &&
            (max == null || duration <= max);
      }(),
      Lossless(:final lossless) => AudioFormat.of(track).lossless == lossless,
    };
  }

  static void _sort(
    List<Track> tracks,
    SmartSort sort,
    _Context context,
    int seed,
  ) {
    if (sort == SmartSort.random) {
      // Sorted first, so the shuffle does not depend on the library's order.
      tracks
        ..sort(_byTitle)
        ..shuffle(math.Random(seed));
      return;
    }
    final stats = context.stats;
    int byKey(Track a, Track b) => switch (sort) {
      SmartSort.title => 0,
      SmartSort.artist => sortKey(a.artist).compareTo(sortKey(b.artist)),
      SmartSort.album => sortKey(a.album).compareTo(sortKey(b.album)),
      SmartSort.year => _nullsLast(a.year, b.year, (x, y) => y - x),
      SmartSort.addedNewest => _nullsLast(
        a.dateAdded,
        b.dateAdded,
        (x, y) => y.compareTo(x),
      ),
      SmartSort.addedOldest => _nullsLast(
        a.dateAdded,
        b.dateAdded,
        (x, y) => x.compareTo(y),
      ),
      SmartSort.mostPlayed => stats.total(b.id) - stats.total(a.id),
      SmartSort.leastPlayed => stats.total(a.id) - stats.total(b.id),
      SmartSort.lastPlayedRecent => _nullsLast(
        stats.lastDay(a.id),
        stats.lastDay(b.id),
        (x, y) => y - x,
      ),
      // Never played counts as oldest of all.
      SmartSort.lastPlayedOldest => _nullsFirst(
        stats.lastDay(a.id),
        stats.lastDay(b.id),
        (x, y) => x - y,
      ),
      SmartSort.random => 0,
    };
    tracks.sort((a, b) {
      final key = byKey(a, b);
      return key != 0 ? key : _byTitle(a, b);
    });
  }

  /// Title, then id: ties always break the same way.
  static int _byTitle(Track a, Track b) {
    final title = sortKey(a.title).compareTo(sortKey(b.title));
    return title != 0 ? title : a.id.compareTo(b.id);
  }

  static int _nullsLast<T>(T? a, T? b, int Function(T, T) compare) =>
      switch ((a, b)) {
        (null, null) => 0,
        (null, _) => 1,
        (_, null) => -1,
        (final x?, final y?) => compare(x, y),
      };

  static int _nullsFirst<T>(T? a, T? b, int Function(T, T) compare) =>
      -_nullsLast<T>(a, b, (x, y) => -compare(x, y));
}

final class _Context {
  const _Context(this.stats, this.liked, this.today);

  final TrackStats stats;
  final Set<String> liked;
  final int today;
}
