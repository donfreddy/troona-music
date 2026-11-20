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

  /// How many songs [evaluate] returns, without sorting them: the editor
  /// counts at each change.
  static int count(
    SmartRules rules,
    List<Track> library, {
    required TrackStats stats,
    required Set<String> liked,
    required int today,
  }) {
    final context = _Context(stats, liked, today);
    final kept = library.where((t) => _keeps(rules, t, context)).length;
    final limit = rules.limit;
    return limit == null ? kept : math.min(kept, math.max(limit, 0));
  }

  /// Plays counted by [SmartSort.mostPlayedMonth].
  static const monthDays = 30;

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
        final found = foldedKey(value).contains(foldedKey(text));
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
    // Each text's key worked out once, not at every comparison.
    final keys = <String, String>{};
    String key(String text) => keys[text] ??= sortKey(text);
    int byTitle(Track a, Track b) {
      final title = key(a.title).compareTo(key(b.title));
      return title != 0 ? title : a.id.compareTo(b.id);
    }

    if (sort == SmartSort.random) {
      // Each song draws its place from the seed and its id alone: a song
      // coming or going leaves the others in the same order.
      final draws = {for (final t in tracks) t.id: _draw(seed, t.id)};
      tracks.sort((a, b) {
        final draw = draws[a.id]!.compareTo(draws[b.id]!);
        return draw != 0 ? draw : byTitle(a, b);
      });
      return;
    }
    final stats = context.stats;
    final today = context.today;
    final month = <String, int>{};
    int monthPlays(Track t) =>
        month[t.id] ??= stats.playsBetween(t.id, today - monthDays + 1, today);
    int byKey(Track a, Track b) => switch (sort) {
      SmartSort.title => 0,
      SmartSort.artist => key(a.artist).compareTo(key(b.artist)),
      SmartSort.album => key(a.album).compareTo(key(b.album)),
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
      SmartSort.mostPlayedMonth => monthPlays(b) - monthPlays(a),
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
    // Ties break by title, then id: always the same way.
    tracks.sort((a, b) {
      final order = byKey(a, b);
      return order != 0 ? order : byTitle(a, b);
    });
  }

  /// A song's random place: FNV-1a over [seed] and [id], 32 bits.
  static int _draw(int seed, String id) {
    var hash = 0x811c9dc5;
    void mix(int byte) {
      hash ^= byte & 0xff;
      hash = (hash * 0x01000193) & 0xffffffff;
    }

    for (var i = 0; i < 4; i++) {
      mix(seed >> (8 * i));
    }
    for (final unit in id.codeUnits) {
      mix(unit);
      mix(unit >> 8);
    }
    return hash;
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
