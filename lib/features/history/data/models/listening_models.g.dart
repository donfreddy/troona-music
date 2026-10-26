// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listening_models.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetListeningDayModelCollection on Isar {
  IsarCollection<int, ListeningDayModel> get listeningDayModels =>
      this.collection();
}

final ListeningDayModelSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'ListeningDayModel',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'plays', type: IsarType.long),
      IsarPropertySchema(name: 'listenedMs', type: IsarType.long),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<int, ListeningDayModel>(
    serialize: serializeListeningDayModel,
    deserialize: deserializeListeningDayModel,
    deserializeProperty: deserializeListeningDayModelProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeListeningDayModel(IsarWriter writer, ListeningDayModel object) {
  IsarCore.writeLong(writer, 1, object.plays);
  IsarCore.writeLong(writer, 2, object.listenedMs);
  return object.id;
}

@isarProtected
ListeningDayModel deserializeListeningDayModel(IsarReader reader) {
  final object = ListeningDayModel();
  object.id = IsarCore.readId(reader);
  object.plays = IsarCore.readLong(reader, 1);
  object.listenedMs = IsarCore.readLong(reader, 2);
  return object;
}

@isarProtected
dynamic deserializeListeningDayModelProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readLong(reader, 1);
    case 2:
      return IsarCore.readLong(reader, 2);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _ListeningDayModelUpdate {
  bool call({required int id, int? plays, int? listenedMs});
}

class _ListeningDayModelUpdateImpl implements _ListeningDayModelUpdate {
  const _ListeningDayModelUpdateImpl(this.collection);

  final IsarCollection<int, ListeningDayModel> collection;

  @override
  bool call({
    required int id,
    Object? plays = ignore,
    Object? listenedMs = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (plays != ignore) 1: plays as int?,
            if (listenedMs != ignore) 2: listenedMs as int?,
          },
        ) >
        0;
  }
}

sealed class _ListeningDayModelUpdateAll {
  int call({required List<int> id, int? plays, int? listenedMs});
}

class _ListeningDayModelUpdateAllImpl implements _ListeningDayModelUpdateAll {
  const _ListeningDayModelUpdateAllImpl(this.collection);

  final IsarCollection<int, ListeningDayModel> collection;

  @override
  int call({
    required List<int> id,
    Object? plays = ignore,
    Object? listenedMs = ignore,
  }) {
    return collection.updateProperties(id, {
      if (plays != ignore) 1: plays as int?,
      if (listenedMs != ignore) 2: listenedMs as int?,
    });
  }
}

extension ListeningDayModelUpdate on IsarCollection<int, ListeningDayModel> {
  _ListeningDayModelUpdate get update => _ListeningDayModelUpdateImpl(this);

  _ListeningDayModelUpdateAll get updateAll =>
      _ListeningDayModelUpdateAllImpl(this);
}

sealed class _ListeningDayModelQueryUpdate {
  int call({int? plays, int? listenedMs});
}

class _ListeningDayModelQueryUpdateImpl
    implements _ListeningDayModelQueryUpdate {
  const _ListeningDayModelQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<ListeningDayModel> query;
  final int? limit;

  @override
  int call({Object? plays = ignore, Object? listenedMs = ignore}) {
    return query.updateProperties(limit: limit, {
      if (plays != ignore) 1: plays as int?,
      if (listenedMs != ignore) 2: listenedMs as int?,
    });
  }
}

extension ListeningDayModelQueryUpdate on IsarQuery<ListeningDayModel> {
  _ListeningDayModelQueryUpdate get updateFirst =>
      _ListeningDayModelQueryUpdateImpl(this, limit: 1);

  _ListeningDayModelQueryUpdate get updateAll =>
      _ListeningDayModelQueryUpdateImpl(this);
}

class _ListeningDayModelQueryBuilderUpdateImpl
    implements _ListeningDayModelQueryUpdate {
  const _ListeningDayModelQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<ListeningDayModel, ListeningDayModel, QOperations> query;
  final int? limit;

  @override
  int call({Object? plays = ignore, Object? listenedMs = ignore}) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (plays != ignore) 1: plays as int?,
        if (listenedMs != ignore) 2: listenedMs as int?,
      });
    } finally {
      q.close();
    }
  }
}

extension ListeningDayModelQueryBuilderUpdate
    on QueryBuilder<ListeningDayModel, ListeningDayModel, QOperations> {
  _ListeningDayModelQueryUpdate get updateFirst =>
      _ListeningDayModelQueryBuilderUpdateImpl(this, limit: 1);

  _ListeningDayModelQueryUpdate get updateAll =>
      _ListeningDayModelQueryBuilderUpdateImpl(this);
}

extension ListeningDayModelQueryFilter
    on QueryBuilder<ListeningDayModel, ListeningDayModel, QFilterCondition> {
  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterFilterCondition>
  idEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterFilterCondition>
  idGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterFilterCondition>
  idGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterFilterCondition>
  idLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 0, value: value));
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterFilterCondition>
  idLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterFilterCondition>
  idBetween(int lower, int upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 0, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterFilterCondition>
  playsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value),
      );
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterFilterCondition>
  playsGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 1, value: value),
      );
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterFilterCondition>
  playsGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 1, value: value),
      );
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterFilterCondition>
  playsLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 1, value: value));
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterFilterCondition>
  playsLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 1, value: value),
      );
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterFilterCondition>
  playsBetween(int lower, int upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 1, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterFilterCondition>
  listenedMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterFilterCondition>
  listenedMsGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterFilterCondition>
  listenedMsGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterFilterCondition>
  listenedMsLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 2, value: value));
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterFilterCondition>
  listenedMsLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterFilterCondition>
  listenedMsBetween(int lower, int upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 2, lower: lower, upper: upper),
      );
    });
  }
}

extension ListeningDayModelQueryObject
    on QueryBuilder<ListeningDayModel, ListeningDayModel, QFilterCondition> {}

extension ListeningDayModelQuerySortBy
    on QueryBuilder<ListeningDayModel, ListeningDayModel, QSortBy> {
  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterSortBy>
  sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterSortBy>
  sortByPlays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1);
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterSortBy>
  sortByPlaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc);
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterSortBy>
  sortByListenedMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterSortBy>
  sortByListenedMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }
}

extension ListeningDayModelQuerySortThenBy
    on QueryBuilder<ListeningDayModel, ListeningDayModel, QSortThenBy> {
  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterSortBy>
  thenByPlays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1);
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterSortBy>
  thenByPlaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc);
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterSortBy>
  thenByListenedMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterSortBy>
  thenByListenedMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }
}

extension ListeningDayModelQueryWhereDistinct
    on QueryBuilder<ListeningDayModel, ListeningDayModel, QDistinct> {
  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterDistinct>
  distinctByPlays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1);
    });
  }

  QueryBuilder<ListeningDayModel, ListeningDayModel, QAfterDistinct>
  distinctByListenedMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2);
    });
  }
}

extension ListeningDayModelQueryProperty1
    on QueryBuilder<ListeningDayModel, ListeningDayModel, QProperty> {
  QueryBuilder<ListeningDayModel, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<ListeningDayModel, int, QAfterProperty> playsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<ListeningDayModel, int, QAfterProperty> listenedMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }
}

extension ListeningDayModelQueryProperty2<R>
    on QueryBuilder<ListeningDayModel, R, QAfterProperty> {
  QueryBuilder<ListeningDayModel, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<ListeningDayModel, (R, int), QAfterProperty> playsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<ListeningDayModel, (R, int), QAfterProperty>
  listenedMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }
}

extension ListeningDayModelQueryProperty3<R1, R2>
    on QueryBuilder<ListeningDayModel, (R1, R2), QAfterProperty> {
  QueryBuilder<ListeningDayModel, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<ListeningDayModel, (R1, R2, int), QOperations> playsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<ListeningDayModel, (R1, R2, int), QOperations>
  listenedMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetTrackDayModelCollection on Isar {
  IsarCollection<String, TrackDayModel> get trackDayModels => this.collection();
}

final TrackDayModelSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'TrackDayModel',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'id', type: IsarType.string),
      IsarPropertySchema(name: 'day', type: IsarType.long),
      IsarPropertySchema(name: 'trackId', type: IsarType.string),
      IsarPropertySchema(name: 'plays', type: IsarType.long),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'day',
        properties: ["day"],
        unique: false,
        hash: false,
      ),
    ],
  ),
  converter: IsarObjectConverter<String, TrackDayModel>(
    serialize: serializeTrackDayModel,
    deserialize: deserializeTrackDayModel,
    deserializeProperty: deserializeTrackDayModelProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeTrackDayModel(IsarWriter writer, TrackDayModel object) {
  IsarCore.writeString(writer, 1, object.id);
  IsarCore.writeLong(writer, 2, object.day);
  IsarCore.writeString(writer, 3, object.trackId);
  IsarCore.writeLong(writer, 4, object.plays);
  return Isar.fastHash(object.id);
}

@isarProtected
TrackDayModel deserializeTrackDayModel(IsarReader reader) {
  final object = TrackDayModel();
  object.id = IsarCore.readString(reader, 1) ?? '';
  object.day = IsarCore.readLong(reader, 2);
  object.trackId = IsarCore.readString(reader, 3) ?? '';
  object.plays = IsarCore.readLong(reader, 4);
  return object;
}

@isarProtected
dynamic deserializeTrackDayModelProp(IsarReader reader, int property) {
  switch (property) {
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readLong(reader, 2);
    case 3:
      return IsarCore.readString(reader, 3) ?? '';
    case 4:
      return IsarCore.readLong(reader, 4);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _TrackDayModelUpdate {
  bool call({required String id, int? day, String? trackId, int? plays});
}

class _TrackDayModelUpdateImpl implements _TrackDayModelUpdate {
  const _TrackDayModelUpdateImpl(this.collection);

  final IsarCollection<String, TrackDayModel> collection;

  @override
  bool call({
    required String id,
    Object? day = ignore,
    Object? trackId = ignore,
    Object? plays = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (day != ignore) 2: day as int?,
            if (trackId != ignore) 3: trackId as String?,
            if (plays != ignore) 4: plays as int?,
          },
        ) >
        0;
  }
}

sealed class _TrackDayModelUpdateAll {
  int call({required List<String> id, int? day, String? trackId, int? plays});
}

class _TrackDayModelUpdateAllImpl implements _TrackDayModelUpdateAll {
  const _TrackDayModelUpdateAllImpl(this.collection);

  final IsarCollection<String, TrackDayModel> collection;

  @override
  int call({
    required List<String> id,
    Object? day = ignore,
    Object? trackId = ignore,
    Object? plays = ignore,
  }) {
    return collection.updateProperties(id, {
      if (day != ignore) 2: day as int?,
      if (trackId != ignore) 3: trackId as String?,
      if (plays != ignore) 4: plays as int?,
    });
  }
}

extension TrackDayModelUpdate on IsarCollection<String, TrackDayModel> {
  _TrackDayModelUpdate get update => _TrackDayModelUpdateImpl(this);

  _TrackDayModelUpdateAll get updateAll => _TrackDayModelUpdateAllImpl(this);
}

sealed class _TrackDayModelQueryUpdate {
  int call({int? day, String? trackId, int? plays});
}

class _TrackDayModelQueryUpdateImpl implements _TrackDayModelQueryUpdate {
  const _TrackDayModelQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<TrackDayModel> query;
  final int? limit;

  @override
  int call({
    Object? day = ignore,
    Object? trackId = ignore,
    Object? plays = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (day != ignore) 2: day as int?,
      if (trackId != ignore) 3: trackId as String?,
      if (plays != ignore) 4: plays as int?,
    });
  }
}

extension TrackDayModelQueryUpdate on IsarQuery<TrackDayModel> {
  _TrackDayModelQueryUpdate get updateFirst =>
      _TrackDayModelQueryUpdateImpl(this, limit: 1);

  _TrackDayModelQueryUpdate get updateAll =>
      _TrackDayModelQueryUpdateImpl(this);
}

class _TrackDayModelQueryBuilderUpdateImpl
    implements _TrackDayModelQueryUpdate {
  const _TrackDayModelQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<TrackDayModel, TrackDayModel, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? day = ignore,
    Object? trackId = ignore,
    Object? plays = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (day != ignore) 2: day as int?,
        if (trackId != ignore) 3: trackId as String?,
        if (plays != ignore) 4: plays as int?,
      });
    } finally {
      q.close();
    }
  }
}

extension TrackDayModelQueryBuilderUpdate
    on QueryBuilder<TrackDayModel, TrackDayModel, QOperations> {
  _TrackDayModelQueryUpdate get updateFirst =>
      _TrackDayModelQueryBuilderUpdateImpl(this, limit: 1);

  _TrackDayModelQueryUpdate get updateAll =>
      _TrackDayModelQueryBuilderUpdateImpl(this);
}

extension TrackDayModelQueryFilter
    on QueryBuilder<TrackDayModel, TrackDayModel, QFilterCondition> {
  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
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

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
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

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition> idLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
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

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
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

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition> idContains(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition> idMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
  idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
  idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition> dayEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
  dayGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
  dayGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition> dayLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 2, value: value));
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
  dayLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition> dayBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 2, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
  trackIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
  trackIdGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
  trackIdGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
  trackIdLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
  trackIdLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
  trackIdBetween(String lower, String upper, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
  trackIdStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
  trackIdEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
  trackIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
  trackIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
  trackIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
  trackIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
  playsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
  playsGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
  playsGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
  playsLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 4, value: value));
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
  playsLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterFilterCondition>
  playsBetween(int lower, int upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 4, lower: lower, upper: upper),
      );
    });
  }
}

extension TrackDayModelQueryObject
    on QueryBuilder<TrackDayModel, TrackDayModel, QFilterCondition> {}

extension TrackDayModelQuerySortBy
    on QueryBuilder<TrackDayModel, TrackDayModel, QSortBy> {
  QueryBuilder<TrackDayModel, TrackDayModel, QAfterSortBy> sortById({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterSortBy> sortByIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterSortBy> sortByDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterSortBy> sortByDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterSortBy> sortByTrackId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterSortBy> sortByTrackIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterSortBy> sortByPlays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterSortBy> sortByPlaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }
}

extension TrackDayModelQuerySortThenBy
    on QueryBuilder<TrackDayModel, TrackDayModel, QSortThenBy> {
  QueryBuilder<TrackDayModel, TrackDayModel, QAfterSortBy> thenById({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterSortBy> thenByIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterSortBy> thenByDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterSortBy> thenByDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterSortBy> thenByTrackId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterSortBy> thenByTrackIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterSortBy> thenByPlays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterSortBy> thenByPlaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }
}

extension TrackDayModelQueryWhereDistinct
    on QueryBuilder<TrackDayModel, TrackDayModel, QDistinct> {
  QueryBuilder<TrackDayModel, TrackDayModel, QAfterDistinct> distinctByDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2);
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterDistinct> distinctByTrackId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackDayModel, TrackDayModel, QAfterDistinct> distinctByPlays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4);
    });
  }
}

extension TrackDayModelQueryProperty1
    on QueryBuilder<TrackDayModel, TrackDayModel, QProperty> {
  QueryBuilder<TrackDayModel, String, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<TrackDayModel, int, QAfterProperty> dayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<TrackDayModel, String, QAfterProperty> trackIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<TrackDayModel, int, QAfterProperty> playsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}

extension TrackDayModelQueryProperty2<R>
    on QueryBuilder<TrackDayModel, R, QAfterProperty> {
  QueryBuilder<TrackDayModel, (R, String), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<TrackDayModel, (R, int), QAfterProperty> dayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<TrackDayModel, (R, String), QAfterProperty> trackIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<TrackDayModel, (R, int), QAfterProperty> playsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}

extension TrackDayModelQueryProperty3<R1, R2>
    on QueryBuilder<TrackDayModel, (R1, R2), QAfterProperty> {
  QueryBuilder<TrackDayModel, (R1, R2, String), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<TrackDayModel, (R1, R2, int), QOperations> dayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<TrackDayModel, (R1, R2, String), QOperations> trackIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<TrackDayModel, (R1, R2, int), QOperations> playsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetTrackFirstPlayModelCollection on Isar {
  IsarCollection<String, TrackFirstPlayModel> get trackFirstPlayModels =>
      this.collection();
}

final TrackFirstPlayModelSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'TrackFirstPlayModel',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'id', type: IsarType.string),
      IsarPropertySchema(name: 'day', type: IsarType.long),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'day',
        properties: ["day"],
        unique: false,
        hash: false,
      ),
    ],
  ),
  converter: IsarObjectConverter<String, TrackFirstPlayModel>(
    serialize: serializeTrackFirstPlayModel,
    deserialize: deserializeTrackFirstPlayModel,
    deserializeProperty: deserializeTrackFirstPlayModelProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeTrackFirstPlayModel(
  IsarWriter writer,
  TrackFirstPlayModel object,
) {
  IsarCore.writeString(writer, 1, object.id);
  IsarCore.writeLong(writer, 2, object.day);
  return Isar.fastHash(object.id);
}

@isarProtected
TrackFirstPlayModel deserializeTrackFirstPlayModel(IsarReader reader) {
  final object = TrackFirstPlayModel();
  object.id = IsarCore.readString(reader, 1) ?? '';
  object.day = IsarCore.readLong(reader, 2);
  return object;
}

@isarProtected
dynamic deserializeTrackFirstPlayModelProp(IsarReader reader, int property) {
  switch (property) {
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readLong(reader, 2);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _TrackFirstPlayModelUpdate {
  bool call({required String id, int? day});
}

class _TrackFirstPlayModelUpdateImpl implements _TrackFirstPlayModelUpdate {
  const _TrackFirstPlayModelUpdateImpl(this.collection);

  final IsarCollection<String, TrackFirstPlayModel> collection;

  @override
  bool call({required String id, Object? day = ignore}) {
    return collection.updateProperties(
          [id],
          {if (day != ignore) 2: day as int?},
        ) >
        0;
  }
}

sealed class _TrackFirstPlayModelUpdateAll {
  int call({required List<String> id, int? day});
}

class _TrackFirstPlayModelUpdateAllImpl
    implements _TrackFirstPlayModelUpdateAll {
  const _TrackFirstPlayModelUpdateAllImpl(this.collection);

  final IsarCollection<String, TrackFirstPlayModel> collection;

  @override
  int call({required List<String> id, Object? day = ignore}) {
    return collection.updateProperties(id, {if (day != ignore) 2: day as int?});
  }
}

extension TrackFirstPlayModelUpdate
    on IsarCollection<String, TrackFirstPlayModel> {
  _TrackFirstPlayModelUpdate get update => _TrackFirstPlayModelUpdateImpl(this);

  _TrackFirstPlayModelUpdateAll get updateAll =>
      _TrackFirstPlayModelUpdateAllImpl(this);
}

sealed class _TrackFirstPlayModelQueryUpdate {
  int call({int? day});
}

class _TrackFirstPlayModelQueryUpdateImpl
    implements _TrackFirstPlayModelQueryUpdate {
  const _TrackFirstPlayModelQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<TrackFirstPlayModel> query;
  final int? limit;

  @override
  int call({Object? day = ignore}) {
    return query.updateProperties(limit: limit, {
      if (day != ignore) 2: day as int?,
    });
  }
}

extension TrackFirstPlayModelQueryUpdate on IsarQuery<TrackFirstPlayModel> {
  _TrackFirstPlayModelQueryUpdate get updateFirst =>
      _TrackFirstPlayModelQueryUpdateImpl(this, limit: 1);

  _TrackFirstPlayModelQueryUpdate get updateAll =>
      _TrackFirstPlayModelQueryUpdateImpl(this);
}

class _TrackFirstPlayModelQueryBuilderUpdateImpl
    implements _TrackFirstPlayModelQueryUpdate {
  const _TrackFirstPlayModelQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QOperations>
  query;
  final int? limit;

  @override
  int call({Object? day = ignore}) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (day != ignore) 2: day as int?,
      });
    } finally {
      q.close();
    }
  }
}

extension TrackFirstPlayModelQueryBuilderUpdate
    on QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QOperations> {
  _TrackFirstPlayModelQueryUpdate get updateFirst =>
      _TrackFirstPlayModelQueryBuilderUpdateImpl(this, limit: 1);

  _TrackFirstPlayModelQueryUpdate get updateAll =>
      _TrackFirstPlayModelQueryBuilderUpdateImpl(this);
}

extension TrackFirstPlayModelQueryFilter
    on
        QueryBuilder<
          TrackFirstPlayModel,
          TrackFirstPlayModel,
          QFilterCondition
        > {
  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterFilterCondition>
  idEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterFilterCondition>
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

  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterFilterCondition>
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

  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterFilterCondition>
  idLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterFilterCondition>
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

  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterFilterCondition>
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

  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterFilterCondition>
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

  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterFilterCondition>
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

  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterFilterCondition>
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

  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterFilterCondition>
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

  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterFilterCondition>
  idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterFilterCondition>
  idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterFilterCondition>
  dayEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterFilterCondition>
  dayGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterFilterCondition>
  dayGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterFilterCondition>
  dayLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 2, value: value));
    });
  }

  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterFilterCondition>
  dayLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterFilterCondition>
  dayBetween(int lower, int upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 2, lower: lower, upper: upper),
      );
    });
  }
}

extension TrackFirstPlayModelQueryObject
    on
        QueryBuilder<
          TrackFirstPlayModel,
          TrackFirstPlayModel,
          QFilterCondition
        > {}

extension TrackFirstPlayModelQuerySortBy
    on QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QSortBy> {
  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterSortBy>
  sortById({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterSortBy>
  sortByIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterSortBy>
  sortByDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterSortBy>
  sortByDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }
}

extension TrackFirstPlayModelQuerySortThenBy
    on QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QSortThenBy> {
  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterSortBy>
  thenById({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterSortBy>
  thenByIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterSortBy>
  thenByDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterSortBy>
  thenByDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }
}

extension TrackFirstPlayModelQueryWhereDistinct
    on QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QDistinct> {
  QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QAfterDistinct>
  distinctByDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2);
    });
  }
}

extension TrackFirstPlayModelQueryProperty1
    on QueryBuilder<TrackFirstPlayModel, TrackFirstPlayModel, QProperty> {
  QueryBuilder<TrackFirstPlayModel, String, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<TrackFirstPlayModel, int, QAfterProperty> dayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }
}

extension TrackFirstPlayModelQueryProperty2<R>
    on QueryBuilder<TrackFirstPlayModel, R, QAfterProperty> {
  QueryBuilder<TrackFirstPlayModel, (R, String), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<TrackFirstPlayModel, (R, int), QAfterProperty> dayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }
}

extension TrackFirstPlayModelQueryProperty3<R1, R2>
    on QueryBuilder<TrackFirstPlayModel, (R1, R2), QAfterProperty> {
  QueryBuilder<TrackFirstPlayModel, (R1, R2, String), QOperations>
  idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<TrackFirstPlayModel, (R1, R2, int), QOperations> dayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }
}
