import 'dart:convert';

import 'package:troona/features/library/domain/entities/smart_rules.dart';

/// [SmartRules] as stored with a playlist and in backups.
///
/// Read leniently: a rule of a kind this version does not know (from a
/// newer one), or out of bounds, is left out and the others kept. Rules
/// that cannot be read at all keep nothing ([unreadable]): an empty list
/// the user can edit, never the whole library.
abstract final class SmartRulesJson {
  static const _version = 1;

  /// Kept when the rules cannot be read: nothing passes the limit of 0.
  static const unreadable = SmartRules(limit: 0);

  static Map<String, Object?> encode(SmartRules rules) => {
    'v': _version,
    'all': rules.matchAll,
    'sort': rules.sort.name,
    'limit': ?rules.limit,
    'rules': [for (final r in rules.rules) _encodeRule(r)],
  };

  static String encodeString(SmartRules rules) => jsonEncode(encode(rules));

  /// Null for null; [unreadable] for anything that is not rules.
  static SmartRules? decodeString(String? json) {
    if (json == null) return null;
    try {
      return decode(jsonDecode(json)) ?? unreadable;
    } on FormatException {
      return unreadable;
    }
  }

  /// Null when [json] is not rules at all.
  static SmartRules? decode(Object? json) {
    if (json is! Map) return null;
    final all = json['all'];
    final sort = _enum(SmartSort.values, json['sort']) ?? SmartSort.title;
    final limit = json['limit'];
    final rules = json['rules'];
    if (all is! bool || rules is! List) return null;
    if (limit != null &&
        (limit is! int || limit < 0 || limit > SmartRules.maxLimit)) {
      return null;
    }
    return SmartRules(
      matchAll: all,
      sort: sort,
      limit: limit as int?,
      rules: [for (final r in rules.take(SmartRules.maxRules)) ?_decodeRule(r)],
    );
  }

  static Map<String, Object?> _encodeRule(SmartRule rule) => switch (rule) {
    PlaysInPeriod(:final days, :final atLeast, :final count) => {
      'type': 'plays',
      'days': days,
      'atLeast': atLeast,
      'count': count,
    },
    LastPlayed(:final kind, :final days) => {
      'type': 'lastPlayed',
      'kind': kind.name,
      'days': days,
    },
    AddedWithin(:final days) => {'type': 'added', 'days': days},
    Liked(:final liked) => {'type': 'liked', 'liked': liked},
    TextMatches(:final field, :final text, :final contains) => {
      'type': 'text',
      'field': field.name,
      'text': text,
      'contains': contains,
    },
    YearBetween(:final from, :final to) => {
      'type': 'year',
      'from': ?from,
      'to': ?to,
    },
    DurationBetween(:final min, :final max) => {
      'type': 'duration',
      if (min != null) 'min': min.inSeconds,
      if (max != null) 'max': max.inSeconds,
    },
    Lossless(:final lossless) => {'type': 'lossless', 'lossless': lossless},
  };

  static SmartRule? _decodeRule(Object? json) {
    if (json is! Map) return null;
    int? days(String key, {int max = 36500}) => switch (json[key]) {
      final int d when d >= 0 && d <= max => d,
      _ => null,
    };
    return switch (json['type']) {
      'plays' => switch ((days('days'), json['atLeast'], days('count'))) {
        (final d?, final bool atLeast, final c?) when d > 0 => PlaysInPeriod(
          days: d,
          atLeast: atLeast,
          count: c,
        ),
        _ => null,
      },
      'lastPlayed' => switch ((
        _enum(LastPlayedKind.values, json['kind']),
        days('days'),
      )) {
        (final kind?, final d?) => LastPlayed(kind, days: d),
        _ => null,
      },
      'added' => switch (days('days')) {
        final d? when d > 0 => AddedWithin(d),
        _ => null,
      },
      'liked' => switch (json['liked']) {
        final bool liked => Liked(liked),
        _ => null,
      },
      'text' => switch ((
        _enum(SmartTextField.values, json['field']),
        json['text'],
        json['contains'],
      )) {
        (final field?, final String text, final bool contains)
            when text.trim().isNotEmpty && text.length <= 200 =>
          TextMatches(field, text, contains: contains),
        _ => null,
      },
      'year' => _year(json['from'], json['to']),
      'duration' => _duration(json['min'], json['max']),
      'lossless' => switch (json['lossless']) {
        final bool lossless => Lossless(lossless),
        _ => null,
      },
      _ => null,
    };
  }

  static SmartRule? _year(Object? from, Object? to) {
    bool valid(Object? y) => y == null || (y is int && y >= 0 && y <= 9999);
    if (!valid(from) || !valid(to) || (from == null && to == null)) {
      return null;
    }
    return YearBetween(from: from as int?, to: to as int?);
  }

  static SmartRule? _duration(Object? min, Object? max) {
    bool valid(Object? s) => s == null || (s is int && s >= 0 && s <= 86400);
    if (!valid(min) || !valid(max) || (min == null && max == null)) {
      return null;
    }
    return DurationBetween(
      min: min == null ? null : Duration(seconds: min as int),
      max: max == null ? null : Duration(seconds: max as int),
    );
  }

  static T? _enum<T extends Enum>(List<T> values, Object? name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }
}
