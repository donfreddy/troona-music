import 'package:equatable/equatable.dart';

/// What a smart playlist keeps: rules instead of songs, its list worked
/// out again each time it opens ([SmartPlaylist.evaluate]).
final class SmartRules extends Equatable {
  /// True: a song must pass every rule; false: at least one. No rules keep
  /// every song.
  final bool matchAll;
  final List<SmartRule> rules;
  final SmartSort sort;

  /// The most songs kept, after sorting; null for no limit.
  final int? limit;

  const SmartRules({
    this.matchAll = true,
    this.rules = const [],
    this.sort = SmartSort.title,
    this.limit,
  });

  /// Most songs a limit can name.
  static const maxLimit = 1000;

  /// Most rules a playlist holds.
  static const maxRules = 20;

  SmartRules copyWith({
    bool? matchAll,
    List<SmartRule>? rules,
    SmartSort? sort,
    int? Function()? limit,
  }) => SmartRules(
    matchAll: matchAll ?? this.matchAll,
    rules: rules ?? this.rules,
    sort: sort ?? this.sort,
    limit: limit == null ? this.limit : limit(),
  );

  @override
  List<Object?> get props => [matchAll, rules, sort, limit];
}

enum SmartSort {
  title,
  artist,
  album,
  year,
  addedNewest,
  addedOldest,
  mostPlayed,

  /// Most plays over the last 30 days, today included.
  mostPlayedMonth,
  leastPlayed,
  lastPlayedRecent,
  lastPlayedOldest,
  random,
}

/// A test one song passes or not. Sealed: each kind is evaluated, and a
/// combination that makes no sense (a duration that "contains") cannot be
/// built.
sealed class SmartRule extends Equatable {
  const SmartRule();
}

/// Played at least (or at most) [count] times over the last [days] days,
/// today included.
final class PlaysInPeriod extends SmartRule {
  final int days;
  final bool atLeast;
  final int count;

  const PlaysInPeriod({
    required this.days,
    this.atLeast = true,
    required this.count,
  });

  @override
  List<Object?> get props => [days, atLeast, count];
}

enum LastPlayedKind {
  /// Last played more than `days` ago; a song never played does not count.
  olderThan,

  /// Played within the last `days` days, today included.
  within,

  /// Never played.
  never,
}

final class LastPlayed extends SmartRule {
  final LastPlayedKind kind;

  /// Unused for [LastPlayedKind.never].
  final int days;

  const LastPlayed(this.kind, {this.days = 0});

  @override
  List<Object?> get props => [kind, days];
}

/// Added to the phone within the last [days] days, today included. A song
/// with no date added does not pass.
final class AddedWithin extends SmartRule {
  final int days;

  const AddedWithin(this.days);

  @override
  List<Object?> get props => [days];
}

final class Liked extends SmartRule {
  final bool liked;

  const Liked(this.liked);

  @override
  List<Object?> get props => [liked];
}

enum SmartTextField { artist, album, genre }

/// [field] contains [text], or does not when [contains] is false; case and
/// accents ignored. A song with no genre contains nothing.
final class TextMatches extends SmartRule {
  final SmartTextField field;
  final String text;
  final bool contains;

  const TextMatches(this.field, this.text, {this.contains = true});

  @override
  List<Object?> get props => [field, text, contains];
}

/// From [from] to [to], both included; null leaves that end open. A song
/// with no year does not pass.
final class YearBetween extends SmartRule {
  final int? from;
  final int? to;

  const YearBetween({this.from, this.to});

  @override
  List<Object?> get props => [from, to];
}

/// From [min] to [max], both included; null leaves that end open.
final class DurationBetween extends SmartRule {
  final Duration? min;
  final Duration? max;

  const DurationBetween({this.min, this.max});

  @override
  List<Object?> get props => [min, max];
}

/// In a lossless format (FLAC, WAV), or not.
final class Lossless extends SmartRule {
  final bool lossless;

  const Lossless(this.lossless);

  @override
  List<Object?> get props => [lossless];
}
