// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_edges_model.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetTrackEdgesModelCollection on Isar {
  IsarCollection<String, TrackEdgesModel> get trackEdgesModels =>
      this.collection();
}

final TrackEdgesModelSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'TrackEdgesModel',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'id', type: IsarType.string),
      IsarPropertySchema(name: 'size', type: IsarType.long),
      IsarPropertySchema(name: 'modifiedMs', type: IsarType.long),
      IsarPropertySchema(name: 'musicStartMs', type: IsarType.long),
      IsarPropertySchema(name: 'musicEndMs', type: IsarType.long),
      IsarPropertySchema(name: 'fadeDownMs', type: IsarType.long),
      IsarPropertySchema(name: 'analyzedAt', type: IsarType.dateTime),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<String, TrackEdgesModel>(
    serialize: serializeTrackEdgesModel,
    deserialize: deserializeTrackEdgesModel,
    deserializeProperty: deserializeTrackEdgesModelProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeTrackEdgesModel(IsarWriter writer, TrackEdgesModel object) {
  IsarCore.writeString(writer, 1, object.id);
  IsarCore.writeLong(writer, 2, object.size);
  IsarCore.writeLong(writer, 3, object.modifiedMs ?? -9223372036854775808);
  IsarCore.writeLong(writer, 4, object.musicStartMs ?? -9223372036854775808);
  IsarCore.writeLong(writer, 5, object.musicEndMs ?? -9223372036854775808);
  IsarCore.writeLong(writer, 6, object.fadeDownMs ?? -9223372036854775808);
  IsarCore.writeLong(
    writer,
    7,
    object.analyzedAt.toUtc().microsecondsSinceEpoch,
  );
  return Isar.fastHash(object.id);
}

@isarProtected
TrackEdgesModel deserializeTrackEdgesModel(IsarReader reader) {
  final object = TrackEdgesModel();
  object.id = IsarCore.readString(reader, 1) ?? '';
  object.size = IsarCore.readLong(reader, 2);
  {
    final value = IsarCore.readLong(reader, 3);
    if (value == -9223372036854775808) {
      object.modifiedMs = null;
    } else {
      object.modifiedMs = value;
    }
  }
  {
    final value = IsarCore.readLong(reader, 4);
    if (value == -9223372036854775808) {
      object.musicStartMs = null;
    } else {
      object.musicStartMs = value;
    }
  }
  {
    final value = IsarCore.readLong(reader, 5);
    if (value == -9223372036854775808) {
      object.musicEndMs = null;
    } else {
      object.musicEndMs = value;
    }
  }
  {
    final value = IsarCore.readLong(reader, 6);
    if (value == -9223372036854775808) {
      object.fadeDownMs = null;
    } else {
      object.fadeDownMs = value;
    }
  }
  {
    final value = IsarCore.readLong(reader, 7);
    if (value == -9223372036854775808) {
      object.analyzedAt = DateTime.fromMillisecondsSinceEpoch(
        0,
        isUtc: true,
      ).toLocal();
    } else {
      object.analyzedAt = DateTime.fromMicrosecondsSinceEpoch(
        value,
        isUtc: true,
      ).toLocal();
    }
  }
  return object;
}

@isarProtected
dynamic deserializeTrackEdgesModelProp(IsarReader reader, int property) {
  switch (property) {
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readLong(reader, 2);
    case 3:
      {
        final value = IsarCore.readLong(reader, 3);
        if (value == -9223372036854775808) {
          return null;
        } else {
          return value;
        }
      }
    case 4:
      {
        final value = IsarCore.readLong(reader, 4);
        if (value == -9223372036854775808) {
          return null;
        } else {
          return value;
        }
      }
    case 5:
      {
        final value = IsarCore.readLong(reader, 5);
        if (value == -9223372036854775808) {
          return null;
        } else {
          return value;
        }
      }
    case 6:
      {
        final value = IsarCore.readLong(reader, 6);
        if (value == -9223372036854775808) {
          return null;
        } else {
          return value;
        }
      }
    case 7:
      {
        final value = IsarCore.readLong(reader, 7);
        if (value == -9223372036854775808) {
          return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal();
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(
            value,
            isUtc: true,
          ).toLocal();
        }
      }
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _TrackEdgesModelUpdate {
  bool call({
    required String id,
    int? size,
    int? modifiedMs,
    int? musicStartMs,
    int? musicEndMs,
    int? fadeDownMs,
    DateTime? analyzedAt,
  });
}

class _TrackEdgesModelUpdateImpl implements _TrackEdgesModelUpdate {
  const _TrackEdgesModelUpdateImpl(this.collection);

  final IsarCollection<String, TrackEdgesModel> collection;

  @override
  bool call({
    required String id,
    Object? size = ignore,
    Object? modifiedMs = ignore,
    Object? musicStartMs = ignore,
    Object? musicEndMs = ignore,
    Object? fadeDownMs = ignore,
    Object? analyzedAt = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (size != ignore) 2: size as int?,
            if (modifiedMs != ignore) 3: modifiedMs as int?,
            if (musicStartMs != ignore) 4: musicStartMs as int?,
            if (musicEndMs != ignore) 5: musicEndMs as int?,
            if (fadeDownMs != ignore) 6: fadeDownMs as int?,
            if (analyzedAt != ignore) 7: analyzedAt as DateTime?,
          },
        ) >
        0;
  }
}

sealed class _TrackEdgesModelUpdateAll {
  int call({
    required List<String> id,
    int? size,
    int? modifiedMs,
    int? musicStartMs,
    int? musicEndMs,
    int? fadeDownMs,
    DateTime? analyzedAt,
  });
}

class _TrackEdgesModelUpdateAllImpl implements _TrackEdgesModelUpdateAll {
  const _TrackEdgesModelUpdateAllImpl(this.collection);

  final IsarCollection<String, TrackEdgesModel> collection;

  @override
  int call({
    required List<String> id,
    Object? size = ignore,
    Object? modifiedMs = ignore,
    Object? musicStartMs = ignore,
    Object? musicEndMs = ignore,
    Object? fadeDownMs = ignore,
    Object? analyzedAt = ignore,
  }) {
    return collection.updateProperties(id, {
      if (size != ignore) 2: size as int?,
      if (modifiedMs != ignore) 3: modifiedMs as int?,
      if (musicStartMs != ignore) 4: musicStartMs as int?,
      if (musicEndMs != ignore) 5: musicEndMs as int?,
      if (fadeDownMs != ignore) 6: fadeDownMs as int?,
      if (analyzedAt != ignore) 7: analyzedAt as DateTime?,
    });
  }
}

extension TrackEdgesModelUpdate on IsarCollection<String, TrackEdgesModel> {
  _TrackEdgesModelUpdate get update => _TrackEdgesModelUpdateImpl(this);

  _TrackEdgesModelUpdateAll get updateAll =>
      _TrackEdgesModelUpdateAllImpl(this);
}

sealed class _TrackEdgesModelQueryUpdate {
  int call({
    int? size,
    int? modifiedMs,
    int? musicStartMs,
    int? musicEndMs,
    int? fadeDownMs,
    DateTime? analyzedAt,
  });
}

class _TrackEdgesModelQueryUpdateImpl implements _TrackEdgesModelQueryUpdate {
  const _TrackEdgesModelQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<TrackEdgesModel> query;
  final int? limit;

  @override
  int call({
    Object? size = ignore,
    Object? modifiedMs = ignore,
    Object? musicStartMs = ignore,
    Object? musicEndMs = ignore,
    Object? fadeDownMs = ignore,
    Object? analyzedAt = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (size != ignore) 2: size as int?,
      if (modifiedMs != ignore) 3: modifiedMs as int?,
      if (musicStartMs != ignore) 4: musicStartMs as int?,
      if (musicEndMs != ignore) 5: musicEndMs as int?,
      if (fadeDownMs != ignore) 6: fadeDownMs as int?,
      if (analyzedAt != ignore) 7: analyzedAt as DateTime?,
    });
  }
}

extension TrackEdgesModelQueryUpdate on IsarQuery<TrackEdgesModel> {
  _TrackEdgesModelQueryUpdate get updateFirst =>
      _TrackEdgesModelQueryUpdateImpl(this, limit: 1);

  _TrackEdgesModelQueryUpdate get updateAll =>
      _TrackEdgesModelQueryUpdateImpl(this);
}

class _TrackEdgesModelQueryBuilderUpdateImpl
    implements _TrackEdgesModelQueryUpdate {
  const _TrackEdgesModelQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<TrackEdgesModel, TrackEdgesModel, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? size = ignore,
    Object? modifiedMs = ignore,
    Object? musicStartMs = ignore,
    Object? musicEndMs = ignore,
    Object? fadeDownMs = ignore,
    Object? analyzedAt = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (size != ignore) 2: size as int?,
        if (modifiedMs != ignore) 3: modifiedMs as int?,
        if (musicStartMs != ignore) 4: musicStartMs as int?,
        if (musicEndMs != ignore) 5: musicEndMs as int?,
        if (fadeDownMs != ignore) 6: fadeDownMs as int?,
        if (analyzedAt != ignore) 7: analyzedAt as DateTime?,
      });
    } finally {
      q.close();
    }
  }
}

extension TrackEdgesModelQueryBuilderUpdate
    on QueryBuilder<TrackEdgesModel, TrackEdgesModel, QOperations> {
  _TrackEdgesModelQueryUpdate get updateFirst =>
      _TrackEdgesModelQueryBuilderUpdateImpl(this, limit: 1);

  _TrackEdgesModelQueryUpdate get updateAll =>
      _TrackEdgesModelQueryBuilderUpdateImpl(this);
}

extension TrackEdgesModelQueryFilter
    on QueryBuilder<TrackEdgesModel, TrackEdgesModel, QFilterCondition> {
  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  idEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
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

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
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

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  idLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
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

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
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

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
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

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
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

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
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

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
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

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  sizeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  sizeGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  sizeGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  sizeLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 2, value: value));
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  sizeLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  sizeBetween(int lower, int upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 2, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  modifiedMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 3));
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  modifiedMsIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 3));
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  modifiedMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  modifiedMsGreaterThan(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  modifiedMsGreaterThanOrEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  modifiedMsLessThan(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 3, value: value));
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  modifiedMsLessThanOrEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  modifiedMsBetween(int? lower, int? upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 3, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  musicStartMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  musicStartMsIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  musicStartMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  musicStartMsGreaterThan(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  musicStartMsGreaterThanOrEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  musicStartMsLessThan(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 4, value: value));
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  musicStartMsLessThanOrEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  musicStartMsBetween(int? lower, int? upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 4, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  musicEndMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  musicEndMsIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  musicEndMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 5, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  musicEndMsGreaterThan(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 5, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  musicEndMsGreaterThanOrEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 5, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  musicEndMsLessThan(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 5, value: value));
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  musicEndMsLessThanOrEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 5, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  musicEndMsBetween(int? lower, int? upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 5, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  fadeDownMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 6));
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  fadeDownMsIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 6));
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  fadeDownMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 6, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  fadeDownMsGreaterThan(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 6, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  fadeDownMsGreaterThanOrEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 6, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  fadeDownMsLessThan(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 6, value: value));
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  fadeDownMsLessThanOrEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 6, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  fadeDownMsBetween(int? lower, int? upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 6, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  analyzedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 7, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  analyzedAtGreaterThan(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 7, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  analyzedAtGreaterThanOrEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 7, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  analyzedAtLessThan(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 7, value: value));
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  analyzedAtLessThanOrEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 7, value: value),
      );
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterFilterCondition>
  analyzedAtBetween(DateTime lower, DateTime upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 7, lower: lower, upper: upper),
      );
    });
  }
}

extension TrackEdgesModelQueryObject
    on QueryBuilder<TrackEdgesModel, TrackEdgesModel, QFilterCondition> {}

extension TrackEdgesModelQuerySortBy
    on QueryBuilder<TrackEdgesModel, TrackEdgesModel, QSortBy> {
  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy> sortById({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy> sortByIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy> sortBySize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy>
  sortBySizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy>
  sortByModifiedMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy>
  sortByModifiedMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy>
  sortByMusicStartMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy>
  sortByMusicStartMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy>
  sortByMusicEndMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy>
  sortByMusicEndMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy>
  sortByFadeDownMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy>
  sortByFadeDownMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy>
  sortByAnalyzedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy>
  sortByAnalyzedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, sort: Sort.desc);
    });
  }
}

extension TrackEdgesModelQuerySortThenBy
    on QueryBuilder<TrackEdgesModel, TrackEdgesModel, QSortThenBy> {
  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy> thenById({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy> thenByIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy> thenBySize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy>
  thenBySizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy>
  thenByModifiedMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy>
  thenByModifiedMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy>
  thenByMusicStartMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy>
  thenByMusicStartMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy>
  thenByMusicEndMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy>
  thenByMusicEndMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy>
  thenByFadeDownMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy>
  thenByFadeDownMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy>
  thenByAnalyzedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterSortBy>
  thenByAnalyzedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, sort: Sort.desc);
    });
  }
}

extension TrackEdgesModelQueryWhereDistinct
    on QueryBuilder<TrackEdgesModel, TrackEdgesModel, QDistinct> {
  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterDistinct>
  distinctBySize() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterDistinct>
  distinctByModifiedMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterDistinct>
  distinctByMusicStartMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterDistinct>
  distinctByMusicEndMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(5);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterDistinct>
  distinctByFadeDownMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(6);
    });
  }

  QueryBuilder<TrackEdgesModel, TrackEdgesModel, QAfterDistinct>
  distinctByAnalyzedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(7);
    });
  }
}

extension TrackEdgesModelQueryProperty1
    on QueryBuilder<TrackEdgesModel, TrackEdgesModel, QProperty> {
  QueryBuilder<TrackEdgesModel, String, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<TrackEdgesModel, int, QAfterProperty> sizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<TrackEdgesModel, int?, QAfterProperty> modifiedMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<TrackEdgesModel, int?, QAfterProperty> musicStartMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<TrackEdgesModel, int?, QAfterProperty> musicEndMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<TrackEdgesModel, int?, QAfterProperty> fadeDownMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<TrackEdgesModel, DateTime, QAfterProperty> analyzedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }
}

extension TrackEdgesModelQueryProperty2<R>
    on QueryBuilder<TrackEdgesModel, R, QAfterProperty> {
  QueryBuilder<TrackEdgesModel, (R, String), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<TrackEdgesModel, (R, int), QAfterProperty> sizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<TrackEdgesModel, (R, int?), QAfterProperty>
  modifiedMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<TrackEdgesModel, (R, int?), QAfterProperty>
  musicStartMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<TrackEdgesModel, (R, int?), QAfterProperty>
  musicEndMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<TrackEdgesModel, (R, int?), QAfterProperty>
  fadeDownMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<TrackEdgesModel, (R, DateTime), QAfterProperty>
  analyzedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }
}

extension TrackEdgesModelQueryProperty3<R1, R2>
    on QueryBuilder<TrackEdgesModel, (R1, R2), QAfterProperty> {
  QueryBuilder<TrackEdgesModel, (R1, R2, String), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<TrackEdgesModel, (R1, R2, int), QOperations> sizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<TrackEdgesModel, (R1, R2, int?), QOperations>
  modifiedMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<TrackEdgesModel, (R1, R2, int?), QOperations>
  musicStartMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<TrackEdgesModel, (R1, R2, int?), QOperations>
  musicEndMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<TrackEdgesModel, (R1, R2, int?), QOperations>
  fadeDownMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<TrackEdgesModel, (R1, R2, DateTime), QOperations>
  analyzedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }
}
