// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_event_model.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetPlayEventModelCollection on Isar {
  IsarCollection<int, PlayEventModel> get playEventModels => this.collection();
}

final PlayEventModelSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'PlayEventModel',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'trackId', type: IsarType.string),
      IsarPropertySchema(name: 'playedAt', type: IsarType.dateTime),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'playedAt',
        properties: ["playedAt"],
        unique: false,
        hash: false,
      ),
    ],
  ),
  converter: IsarObjectConverter<int, PlayEventModel>(
    serialize: serializePlayEventModel,
    deserialize: deserializePlayEventModel,
    deserializeProperty: deserializePlayEventModelProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializePlayEventModel(IsarWriter writer, PlayEventModel object) {
  IsarCore.writeString(writer, 1, object.trackId);
  IsarCore.writeLong(writer, 2, object.playedAt.toUtc().microsecondsSinceEpoch);
  return object.id;
}

@isarProtected
PlayEventModel deserializePlayEventModel(IsarReader reader) {
  final object = PlayEventModel();
  object.id = IsarCore.readId(reader);
  object.trackId = IsarCore.readString(reader, 1) ?? '';
  {
    final value = IsarCore.readLong(reader, 2);
    if (value == -9223372036854775808) {
      object.playedAt = DateTime.fromMillisecondsSinceEpoch(
        0,
        isUtc: true,
      ).toLocal();
    } else {
      object.playedAt = DateTime.fromMicrosecondsSinceEpoch(
        value,
        isUtc: true,
      ).toLocal();
    }
  }
  return object;
}

@isarProtected
dynamic deserializePlayEventModelProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      {
        final value = IsarCore.readLong(reader, 2);
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

sealed class _PlayEventModelUpdate {
  bool call({required int id, String? trackId, DateTime? playedAt});
}

class _PlayEventModelUpdateImpl implements _PlayEventModelUpdate {
  const _PlayEventModelUpdateImpl(this.collection);

  final IsarCollection<int, PlayEventModel> collection;

  @override
  bool call({
    required int id,
    Object? trackId = ignore,
    Object? playedAt = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (trackId != ignore) 1: trackId as String?,
            if (playedAt != ignore) 2: playedAt as DateTime?,
          },
        ) >
        0;
  }
}

sealed class _PlayEventModelUpdateAll {
  int call({required List<int> id, String? trackId, DateTime? playedAt});
}

class _PlayEventModelUpdateAllImpl implements _PlayEventModelUpdateAll {
  const _PlayEventModelUpdateAllImpl(this.collection);

  final IsarCollection<int, PlayEventModel> collection;

  @override
  int call({
    required List<int> id,
    Object? trackId = ignore,
    Object? playedAt = ignore,
  }) {
    return collection.updateProperties(id, {
      if (trackId != ignore) 1: trackId as String?,
      if (playedAt != ignore) 2: playedAt as DateTime?,
    });
  }
}

extension PlayEventModelUpdate on IsarCollection<int, PlayEventModel> {
  _PlayEventModelUpdate get update => _PlayEventModelUpdateImpl(this);

  _PlayEventModelUpdateAll get updateAll => _PlayEventModelUpdateAllImpl(this);
}

sealed class _PlayEventModelQueryUpdate {
  int call({String? trackId, DateTime? playedAt});
}

class _PlayEventModelQueryUpdateImpl implements _PlayEventModelQueryUpdate {
  const _PlayEventModelQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<PlayEventModel> query;
  final int? limit;

  @override
  int call({Object? trackId = ignore, Object? playedAt = ignore}) {
    return query.updateProperties(limit: limit, {
      if (trackId != ignore) 1: trackId as String?,
      if (playedAt != ignore) 2: playedAt as DateTime?,
    });
  }
}

extension PlayEventModelQueryUpdate on IsarQuery<PlayEventModel> {
  _PlayEventModelQueryUpdate get updateFirst =>
      _PlayEventModelQueryUpdateImpl(this, limit: 1);

  _PlayEventModelQueryUpdate get updateAll =>
      _PlayEventModelQueryUpdateImpl(this);
}

class _PlayEventModelQueryBuilderUpdateImpl
    implements _PlayEventModelQueryUpdate {
  const _PlayEventModelQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<PlayEventModel, PlayEventModel, QOperations> query;
  final int? limit;

  @override
  int call({Object? trackId = ignore, Object? playedAt = ignore}) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (trackId != ignore) 1: trackId as String?,
        if (playedAt != ignore) 2: playedAt as DateTime?,
      });
    } finally {
      q.close();
    }
  }
}

extension PlayEventModelQueryBuilderUpdate
    on QueryBuilder<PlayEventModel, PlayEventModel, QOperations> {
  _PlayEventModelQueryUpdate get updateFirst =>
      _PlayEventModelQueryBuilderUpdateImpl(this, limit: 1);

  _PlayEventModelQueryUpdate get updateAll =>
      _PlayEventModelQueryBuilderUpdateImpl(this);
}

extension PlayEventModelQueryFilter
    on QueryBuilder<PlayEventModel, PlayEventModel, QFilterCondition> {
  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition> idEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition>
  idGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition>
  idGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition>
  idLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 0, value: value));
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition>
  idLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition> idBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 0, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition>
  trackIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition>
  trackIdGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition>
  trackIdGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition>
  trackIdLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition>
  trackIdLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition>
  trackIdBetween(String lower, String upper, {bool caseSensitive = true}) {
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

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition>
  trackIdStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition>
  trackIdEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition>
  trackIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition>
  trackIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition>
  trackIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition>
  trackIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition>
  playedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition>
  playedAtGreaterThan(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition>
  playedAtGreaterThanOrEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition>
  playedAtLessThan(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 2, value: value));
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition>
  playedAtLessThanOrEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterFilterCondition>
  playedAtBetween(DateTime lower, DateTime upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 2, lower: lower, upper: upper),
      );
    });
  }
}

extension PlayEventModelQueryObject
    on QueryBuilder<PlayEventModel, PlayEventModel, QFilterCondition> {}

extension PlayEventModelQuerySortBy
    on QueryBuilder<PlayEventModel, PlayEventModel, QSortBy> {
  QueryBuilder<PlayEventModel, PlayEventModel, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterSortBy> sortByTrackId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterSortBy> sortByTrackIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterSortBy> sortByPlayedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterSortBy>
  sortByPlayedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }
}

extension PlayEventModelQuerySortThenBy
    on QueryBuilder<PlayEventModel, PlayEventModel, QSortThenBy> {
  QueryBuilder<PlayEventModel, PlayEventModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterSortBy> thenByTrackId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterSortBy> thenByTrackIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterSortBy> thenByPlayedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterSortBy>
  thenByPlayedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }
}

extension PlayEventModelQueryWhereDistinct
    on QueryBuilder<PlayEventModel, PlayEventModel, QDistinct> {
  QueryBuilder<PlayEventModel, PlayEventModel, QAfterDistinct>
  distinctByTrackId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlayEventModel, PlayEventModel, QAfterDistinct>
  distinctByPlayedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2);
    });
  }
}

extension PlayEventModelQueryProperty1
    on QueryBuilder<PlayEventModel, PlayEventModel, QProperty> {
  QueryBuilder<PlayEventModel, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<PlayEventModel, String, QAfterProperty> trackIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<PlayEventModel, DateTime, QAfterProperty> playedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }
}

extension PlayEventModelQueryProperty2<R>
    on QueryBuilder<PlayEventModel, R, QAfterProperty> {
  QueryBuilder<PlayEventModel, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<PlayEventModel, (R, String), QAfterProperty> trackIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<PlayEventModel, (R, DateTime), QAfterProperty>
  playedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }
}

extension PlayEventModelQueryProperty3<R1, R2>
    on QueryBuilder<PlayEventModel, (R1, R2), QAfterProperty> {
  QueryBuilder<PlayEventModel, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<PlayEventModel, (R1, R2, String), QOperations>
  trackIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<PlayEventModel, (R1, R2, DateTime), QOperations>
  playedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }
}
