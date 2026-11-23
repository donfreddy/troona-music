// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_lyrics_model.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetTrackLyricsModelCollection on Isar {
  IsarCollection<String, TrackLyricsModel> get trackLyricsModels =>
      this.collection();
}

final TrackLyricsModelSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'TrackLyricsModel',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'id', type: IsarType.string),
      IsarPropertySchema(name: 'raw', type: IsarType.string),
      IsarPropertySchema(name: 'source', type: IsarType.string),
      IsarPropertySchema(name: 'offsetMs', type: IsarType.long),
      IsarPropertySchema(name: 'checkedAt', type: IsarType.dateTime),
      IsarPropertySchema(name: 'partial', type: IsarType.bool),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<String, TrackLyricsModel>(
    serialize: serializeTrackLyricsModel,
    deserialize: deserializeTrackLyricsModel,
    deserializeProperty: deserializeTrackLyricsModelProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeTrackLyricsModel(IsarWriter writer, TrackLyricsModel object) {
  IsarCore.writeString(writer, 1, object.id);
  {
    final value = object.raw;
    if (value == null) {
      IsarCore.writeNull(writer, 2);
    } else {
      IsarCore.writeString(writer, 2, value);
    }
  }
  {
    final value = object.source;
    if (value == null) {
      IsarCore.writeNull(writer, 3);
    } else {
      IsarCore.writeString(writer, 3, value);
    }
  }
  IsarCore.writeLong(writer, 4, object.offsetMs);
  IsarCore.writeLong(
    writer,
    5,
    object.checkedAt.toUtc().microsecondsSinceEpoch,
  );
  IsarCore.writeBool(writer, 6, value: object.partial);
  return Isar.fastHash(object.id);
}

@isarProtected
TrackLyricsModel deserializeTrackLyricsModel(IsarReader reader) {
  final object = TrackLyricsModel();
  object.id = IsarCore.readString(reader, 1) ?? '';
  object.raw = IsarCore.readString(reader, 2);
  object.source = IsarCore.readString(reader, 3);
  object.offsetMs = IsarCore.readLong(reader, 4);
  {
    final value = IsarCore.readLong(reader, 5);
    if (value == -9223372036854775808) {
      object.checkedAt = DateTime.fromMillisecondsSinceEpoch(
        0,
        isUtc: true,
      ).toLocal();
    } else {
      object.checkedAt = DateTime.fromMicrosecondsSinceEpoch(
        value,
        isUtc: true,
      ).toLocal();
    }
  }
  object.partial = IsarCore.readBool(reader, 6);
  return object;
}

@isarProtected
dynamic deserializeTrackLyricsModelProp(IsarReader reader, int property) {
  switch (property) {
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readString(reader, 2);
    case 3:
      return IsarCore.readString(reader, 3);
    case 4:
      return IsarCore.readLong(reader, 4);
    case 5:
      {
        final value = IsarCore.readLong(reader, 5);
        if (value == -9223372036854775808) {
          return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal();
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(
            value,
            isUtc: true,
          ).toLocal();
        }
      }
    case 6:
      return IsarCore.readBool(reader, 6);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _TrackLyricsModelUpdate {
  bool call({
    required String id,
    String? raw,
    String? source,
    int? offsetMs,
    DateTime? checkedAt,
    bool? partial,
  });
}

class _TrackLyricsModelUpdateImpl implements _TrackLyricsModelUpdate {
  const _TrackLyricsModelUpdateImpl(this.collection);

  final IsarCollection<String, TrackLyricsModel> collection;

  @override
  bool call({
    required String id,
    Object? raw = ignore,
    Object? source = ignore,
    Object? offsetMs = ignore,
    Object? checkedAt = ignore,
    Object? partial = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (raw != ignore) 2: raw as String?,
            if (source != ignore) 3: source as String?,
            if (offsetMs != ignore) 4: offsetMs as int?,
            if (checkedAt != ignore) 5: checkedAt as DateTime?,
            if (partial != ignore) 6: partial as bool?,
          },
        ) >
        0;
  }
}

sealed class _TrackLyricsModelUpdateAll {
  int call({
    required List<String> id,
    String? raw,
    String? source,
    int? offsetMs,
    DateTime? checkedAt,
    bool? partial,
  });
}

class _TrackLyricsModelUpdateAllImpl implements _TrackLyricsModelUpdateAll {
  const _TrackLyricsModelUpdateAllImpl(this.collection);

  final IsarCollection<String, TrackLyricsModel> collection;

  @override
  int call({
    required List<String> id,
    Object? raw = ignore,
    Object? source = ignore,
    Object? offsetMs = ignore,
    Object? checkedAt = ignore,
    Object? partial = ignore,
  }) {
    return collection.updateProperties(id, {
      if (raw != ignore) 2: raw as String?,
      if (source != ignore) 3: source as String?,
      if (offsetMs != ignore) 4: offsetMs as int?,
      if (checkedAt != ignore) 5: checkedAt as DateTime?,
      if (partial != ignore) 6: partial as bool?,
    });
  }
}

extension TrackLyricsModelUpdate on IsarCollection<String, TrackLyricsModel> {
  _TrackLyricsModelUpdate get update => _TrackLyricsModelUpdateImpl(this);

  _TrackLyricsModelUpdateAll get updateAll =>
      _TrackLyricsModelUpdateAllImpl(this);
}

sealed class _TrackLyricsModelQueryUpdate {
  int call({
    String? raw,
    String? source,
    int? offsetMs,
    DateTime? checkedAt,
    bool? partial,
  });
}

class _TrackLyricsModelQueryUpdateImpl implements _TrackLyricsModelQueryUpdate {
  const _TrackLyricsModelQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<TrackLyricsModel> query;
  final int? limit;

  @override
  int call({
    Object? raw = ignore,
    Object? source = ignore,
    Object? offsetMs = ignore,
    Object? checkedAt = ignore,
    Object? partial = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (raw != ignore) 2: raw as String?,
      if (source != ignore) 3: source as String?,
      if (offsetMs != ignore) 4: offsetMs as int?,
      if (checkedAt != ignore) 5: checkedAt as DateTime?,
      if (partial != ignore) 6: partial as bool?,
    });
  }
}

extension TrackLyricsModelQueryUpdate on IsarQuery<TrackLyricsModel> {
  _TrackLyricsModelQueryUpdate get updateFirst =>
      _TrackLyricsModelQueryUpdateImpl(this, limit: 1);

  _TrackLyricsModelQueryUpdate get updateAll =>
      _TrackLyricsModelQueryUpdateImpl(this);
}

class _TrackLyricsModelQueryBuilderUpdateImpl
    implements _TrackLyricsModelQueryUpdate {
  const _TrackLyricsModelQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<TrackLyricsModel, TrackLyricsModel, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? raw = ignore,
    Object? source = ignore,
    Object? offsetMs = ignore,
    Object? checkedAt = ignore,
    Object? partial = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (raw != ignore) 2: raw as String?,
        if (source != ignore) 3: source as String?,
        if (offsetMs != ignore) 4: offsetMs as int?,
        if (checkedAt != ignore) 5: checkedAt as DateTime?,
        if (partial != ignore) 6: partial as bool?,
      });
    } finally {
      q.close();
    }
  }
}

extension TrackLyricsModelQueryBuilderUpdate
    on QueryBuilder<TrackLyricsModel, TrackLyricsModel, QOperations> {
  _TrackLyricsModelQueryUpdate get updateFirst =>
      _TrackLyricsModelQueryBuilderUpdateImpl(this, limit: 1);

  _TrackLyricsModelQueryUpdate get updateAll =>
      _TrackLyricsModelQueryBuilderUpdateImpl(this);
}

extension TrackLyricsModelQueryFilter
    on QueryBuilder<TrackLyricsModel, TrackLyricsModel, QFilterCondition> {
  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  idEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  idGreaterThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  idGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  idLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  idLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  idBetween(String lower, String upper, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  idStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  idEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 1,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  rawIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 2));
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  rawIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 2));
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  rawEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  rawGreaterThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  rawGreaterThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  rawLessThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  rawLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  rawBetween(String? lower, String? upper, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  rawStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  rawEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  rawContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  rawMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 2,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  rawIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  rawIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  sourceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 3));
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  sourceIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 3));
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  sourceEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  sourceGreaterThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  sourceGreaterThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  sourceLessThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  sourceLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  sourceBetween(String? lower, String? upper, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 3,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  sourceStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  sourceEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  sourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  sourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 3,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  offsetMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  offsetMsGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  offsetMsGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  offsetMsLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 4, value: value));
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  offsetMsLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  offsetMsBetween(int lower, int upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 4, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  checkedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 5, value: value),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  checkedAtGreaterThan(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 5, value: value),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  checkedAtGreaterThanOrEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 5, value: value),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  checkedAtLessThan(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 5, value: value));
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  checkedAtLessThanOrEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 5, value: value),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  checkedAtBetween(DateTime lower, DateTime upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 5, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterFilterCondition>
  partialEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 6, value: value),
      );
    });
  }
}

extension TrackLyricsModelQueryObject
    on QueryBuilder<TrackLyricsModel, TrackLyricsModel, QFilterCondition> {}

extension TrackLyricsModelQuerySortBy
    on QueryBuilder<TrackLyricsModel, TrackLyricsModel, QSortBy> {
  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy> sortById({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy> sortByIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy> sortByRaw({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy> sortByRawDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy> sortBySource({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy>
  sortBySourceDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy>
  sortByOffsetMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy>
  sortByOffsetMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy>
  sortByCheckedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy>
  sortByCheckedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy>
  sortByPartial() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy>
  sortByPartialDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc);
    });
  }
}

extension TrackLyricsModelQuerySortThenBy
    on QueryBuilder<TrackLyricsModel, TrackLyricsModel, QSortThenBy> {
  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy> thenById({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy> thenByIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy> thenByRaw({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy> thenByRawDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy> thenBySource({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy>
  thenBySourceDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy>
  thenByOffsetMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy>
  thenByOffsetMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy>
  thenByCheckedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy>
  thenByCheckedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy>
  thenByPartial() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterSortBy>
  thenByPartialDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc);
    });
  }
}

extension TrackLyricsModelQueryWhereDistinct
    on QueryBuilder<TrackLyricsModel, TrackLyricsModel, QDistinct> {
  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterDistinct>
  distinctByRaw({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterDistinct>
  distinctBySource({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterDistinct>
  distinctByOffsetMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterDistinct>
  distinctByCheckedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(5);
    });
  }

  QueryBuilder<TrackLyricsModel, TrackLyricsModel, QAfterDistinct>
  distinctByPartial() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(6);
    });
  }
}

extension TrackLyricsModelQueryProperty1
    on QueryBuilder<TrackLyricsModel, TrackLyricsModel, QProperty> {
  QueryBuilder<TrackLyricsModel, String, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<TrackLyricsModel, String?, QAfterProperty> rawProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<TrackLyricsModel, String?, QAfterProperty> sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<TrackLyricsModel, int, QAfterProperty> offsetMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<TrackLyricsModel, DateTime, QAfterProperty> checkedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<TrackLyricsModel, bool, QAfterProperty> partialProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }
}

extension TrackLyricsModelQueryProperty2<R>
    on QueryBuilder<TrackLyricsModel, R, QAfterProperty> {
  QueryBuilder<TrackLyricsModel, (R, String), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<TrackLyricsModel, (R, String?), QAfterProperty> rawProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<TrackLyricsModel, (R, String?), QAfterProperty>
  sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<TrackLyricsModel, (R, int), QAfterProperty> offsetMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<TrackLyricsModel, (R, DateTime), QAfterProperty>
  checkedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<TrackLyricsModel, (R, bool), QAfterProperty> partialProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }
}

extension TrackLyricsModelQueryProperty3<R1, R2>
    on QueryBuilder<TrackLyricsModel, (R1, R2), QAfterProperty> {
  QueryBuilder<TrackLyricsModel, (R1, R2, String), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<TrackLyricsModel, (R1, R2, String?), QOperations> rawProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<TrackLyricsModel, (R1, R2, String?), QOperations>
  sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<TrackLyricsModel, (R1, R2, int), QOperations>
  offsetMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<TrackLyricsModel, (R1, R2, DateTime), QOperations>
  checkedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<TrackLyricsModel, (R1, R2, bool), QOperations>
  partialProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }
}
