// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_edit_model.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetTrackEditModelCollection on Isar {
  IsarCollection<int, TrackEditModel> get trackEditModels => this.collection();
}

final TrackEditModelSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'TrackEditModel',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'deviceId', type: IsarType.string),
      IsarPropertySchema(name: 'fileName', type: IsarType.string),
      IsarPropertySchema(name: 'size', type: IsarType.long),
      IsarPropertySchema(name: 'title', type: IsarType.string),
      IsarPropertySchema(name: 'artist', type: IsarType.string),
      IsarPropertySchema(name: 'album', type: IsarType.string),
      IsarPropertySchema(name: 'year', type: IsarType.long),
      IsarPropertySchema(name: 'coverPath', type: IsarType.string),
      IsarPropertySchema(name: 'editedAt', type: IsarType.dateTime),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'deviceId',
        properties: ["deviceId"],
        unique: false,
        hash: false,
      ),
    ],
  ),
  converter: IsarObjectConverter<int, TrackEditModel>(
    serialize: serializeTrackEditModel,
    deserialize: deserializeTrackEditModel,
    deserializeProperty: deserializeTrackEditModelProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeTrackEditModel(IsarWriter writer, TrackEditModel object) {
  IsarCore.writeString(writer, 1, object.deviceId);
  IsarCore.writeString(writer, 2, object.fileName);
  IsarCore.writeLong(writer, 3, object.size);
  {
    final value = object.title;
    if (value == null) {
      IsarCore.writeNull(writer, 4);
    } else {
      IsarCore.writeString(writer, 4, value);
    }
  }
  {
    final value = object.artist;
    if (value == null) {
      IsarCore.writeNull(writer, 5);
    } else {
      IsarCore.writeString(writer, 5, value);
    }
  }
  {
    final value = object.album;
    if (value == null) {
      IsarCore.writeNull(writer, 6);
    } else {
      IsarCore.writeString(writer, 6, value);
    }
  }
  IsarCore.writeLong(writer, 7, object.year ?? -9223372036854775808);
  {
    final value = object.coverPath;
    if (value == null) {
      IsarCore.writeNull(writer, 8);
    } else {
      IsarCore.writeString(writer, 8, value);
    }
  }
  IsarCore.writeLong(writer, 9, object.editedAt.toUtc().microsecondsSinceEpoch);
  return object.id;
}

@isarProtected
TrackEditModel deserializeTrackEditModel(IsarReader reader) {
  final object = TrackEditModel();
  object.id = IsarCore.readId(reader);
  object.deviceId = IsarCore.readString(reader, 1) ?? '';
  object.fileName = IsarCore.readString(reader, 2) ?? '';
  object.size = IsarCore.readLong(reader, 3);
  object.title = IsarCore.readString(reader, 4);
  object.artist = IsarCore.readString(reader, 5);
  object.album = IsarCore.readString(reader, 6);
  {
    final value = IsarCore.readLong(reader, 7);
    if (value == -9223372036854775808) {
      object.year = null;
    } else {
      object.year = value;
    }
  }
  object.coverPath = IsarCore.readString(reader, 8);
  {
    final value = IsarCore.readLong(reader, 9);
    if (value == -9223372036854775808) {
      object.editedAt = DateTime.fromMillisecondsSinceEpoch(
        0,
        isUtc: true,
      ).toLocal();
    } else {
      object.editedAt = DateTime.fromMicrosecondsSinceEpoch(
        value,
        isUtc: true,
      ).toLocal();
    }
  }
  return object;
}

@isarProtected
dynamic deserializeTrackEditModelProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readString(reader, 2) ?? '';
    case 3:
      return IsarCore.readLong(reader, 3);
    case 4:
      return IsarCore.readString(reader, 4);
    case 5:
      return IsarCore.readString(reader, 5);
    case 6:
      return IsarCore.readString(reader, 6);
    case 7:
      {
        final value = IsarCore.readLong(reader, 7);
        if (value == -9223372036854775808) {
          return null;
        } else {
          return value;
        }
      }
    case 8:
      return IsarCore.readString(reader, 8);
    case 9:
      {
        final value = IsarCore.readLong(reader, 9);
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

sealed class _TrackEditModelUpdate {
  bool call({
    required int id,
    String? deviceId,
    String? fileName,
    int? size,
    String? title,
    String? artist,
    String? album,
    int? year,
    String? coverPath,
    DateTime? editedAt,
  });
}

class _TrackEditModelUpdateImpl implements _TrackEditModelUpdate {
  const _TrackEditModelUpdateImpl(this.collection);

  final IsarCollection<int, TrackEditModel> collection;

  @override
  bool call({
    required int id,
    Object? deviceId = ignore,
    Object? fileName = ignore,
    Object? size = ignore,
    Object? title = ignore,
    Object? artist = ignore,
    Object? album = ignore,
    Object? year = ignore,
    Object? coverPath = ignore,
    Object? editedAt = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (deviceId != ignore) 1: deviceId as String?,
            if (fileName != ignore) 2: fileName as String?,
            if (size != ignore) 3: size as int?,
            if (title != ignore) 4: title as String?,
            if (artist != ignore) 5: artist as String?,
            if (album != ignore) 6: album as String?,
            if (year != ignore) 7: year as int?,
            if (coverPath != ignore) 8: coverPath as String?,
            if (editedAt != ignore) 9: editedAt as DateTime?,
          },
        ) >
        0;
  }
}

sealed class _TrackEditModelUpdateAll {
  int call({
    required List<int> id,
    String? deviceId,
    String? fileName,
    int? size,
    String? title,
    String? artist,
    String? album,
    int? year,
    String? coverPath,
    DateTime? editedAt,
  });
}

class _TrackEditModelUpdateAllImpl implements _TrackEditModelUpdateAll {
  const _TrackEditModelUpdateAllImpl(this.collection);

  final IsarCollection<int, TrackEditModel> collection;

  @override
  int call({
    required List<int> id,
    Object? deviceId = ignore,
    Object? fileName = ignore,
    Object? size = ignore,
    Object? title = ignore,
    Object? artist = ignore,
    Object? album = ignore,
    Object? year = ignore,
    Object? coverPath = ignore,
    Object? editedAt = ignore,
  }) {
    return collection.updateProperties(id, {
      if (deviceId != ignore) 1: deviceId as String?,
      if (fileName != ignore) 2: fileName as String?,
      if (size != ignore) 3: size as int?,
      if (title != ignore) 4: title as String?,
      if (artist != ignore) 5: artist as String?,
      if (album != ignore) 6: album as String?,
      if (year != ignore) 7: year as int?,
      if (coverPath != ignore) 8: coverPath as String?,
      if (editedAt != ignore) 9: editedAt as DateTime?,
    });
  }
}

extension TrackEditModelUpdate on IsarCollection<int, TrackEditModel> {
  _TrackEditModelUpdate get update => _TrackEditModelUpdateImpl(this);

  _TrackEditModelUpdateAll get updateAll => _TrackEditModelUpdateAllImpl(this);
}

sealed class _TrackEditModelQueryUpdate {
  int call({
    String? deviceId,
    String? fileName,
    int? size,
    String? title,
    String? artist,
    String? album,
    int? year,
    String? coverPath,
    DateTime? editedAt,
  });
}

class _TrackEditModelQueryUpdateImpl implements _TrackEditModelQueryUpdate {
  const _TrackEditModelQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<TrackEditModel> query;
  final int? limit;

  @override
  int call({
    Object? deviceId = ignore,
    Object? fileName = ignore,
    Object? size = ignore,
    Object? title = ignore,
    Object? artist = ignore,
    Object? album = ignore,
    Object? year = ignore,
    Object? coverPath = ignore,
    Object? editedAt = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (deviceId != ignore) 1: deviceId as String?,
      if (fileName != ignore) 2: fileName as String?,
      if (size != ignore) 3: size as int?,
      if (title != ignore) 4: title as String?,
      if (artist != ignore) 5: artist as String?,
      if (album != ignore) 6: album as String?,
      if (year != ignore) 7: year as int?,
      if (coverPath != ignore) 8: coverPath as String?,
      if (editedAt != ignore) 9: editedAt as DateTime?,
    });
  }
}

extension TrackEditModelQueryUpdate on IsarQuery<TrackEditModel> {
  _TrackEditModelQueryUpdate get updateFirst =>
      _TrackEditModelQueryUpdateImpl(this, limit: 1);

  _TrackEditModelQueryUpdate get updateAll =>
      _TrackEditModelQueryUpdateImpl(this);
}

class _TrackEditModelQueryBuilderUpdateImpl
    implements _TrackEditModelQueryUpdate {
  const _TrackEditModelQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<TrackEditModel, TrackEditModel, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? deviceId = ignore,
    Object? fileName = ignore,
    Object? size = ignore,
    Object? title = ignore,
    Object? artist = ignore,
    Object? album = ignore,
    Object? year = ignore,
    Object? coverPath = ignore,
    Object? editedAt = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (deviceId != ignore) 1: deviceId as String?,
        if (fileName != ignore) 2: fileName as String?,
        if (size != ignore) 3: size as int?,
        if (title != ignore) 4: title as String?,
        if (artist != ignore) 5: artist as String?,
        if (album != ignore) 6: album as String?,
        if (year != ignore) 7: year as int?,
        if (coverPath != ignore) 8: coverPath as String?,
        if (editedAt != ignore) 9: editedAt as DateTime?,
      });
    } finally {
      q.close();
    }
  }
}

extension TrackEditModelQueryBuilderUpdate
    on QueryBuilder<TrackEditModel, TrackEditModel, QOperations> {
  _TrackEditModelQueryUpdate get updateFirst =>
      _TrackEditModelQueryBuilderUpdateImpl(this, limit: 1);

  _TrackEditModelQueryUpdate get updateAll =>
      _TrackEditModelQueryBuilderUpdateImpl(this);
}

extension TrackEditModelQueryFilter
    on QueryBuilder<TrackEditModel, TrackEditModel, QFilterCondition> {
  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition> idEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  idGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  idGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  idLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 0, value: value));
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  idLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition> idBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 0, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  deviceIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  deviceIdGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  deviceIdGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  deviceIdLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  deviceIdLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  deviceIdBetween(String lower, String upper, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  deviceIdStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  deviceIdEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  deviceIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  deviceIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  deviceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  deviceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  fileNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  fileNameGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  fileNameGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  fileNameLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  fileNameLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  fileNameBetween(String lower, String upper, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  fileNameStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  fileNameEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  fileNameContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  fileNameMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  fileNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  fileNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  sizeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  sizeGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  sizeGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  sizeLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 3, value: value));
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  sizeLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  sizeBetween(int lower, int upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 3, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  titleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  titleIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  titleEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 4, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  titleGreaterThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  titleGreaterThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  titleLessThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 4, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  titleLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  titleBetween(String? lower, String? upper, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 4,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  titleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  titleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 4,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 4, value: ''),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 4, value: ''),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  artistIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  artistIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  artistEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 5, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  artistGreaterThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  artistGreaterThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  artistLessThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 5, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  artistLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  artistBetween(String? lower, String? upper, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 5,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  artistStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  artistEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  artistContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  artistMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 5,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  artistIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 5, value: ''),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  artistIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 5, value: ''),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  albumIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 6));
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  albumIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 6));
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  albumEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 6, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  albumGreaterThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  albumGreaterThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  albumLessThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 6, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  albumLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  albumBetween(String? lower, String? upper, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 6,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  albumStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  albumEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  albumContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  albumMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 6,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  albumIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 6, value: ''),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  albumIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 6, value: ''),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  yearIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 7));
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  yearIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 7));
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  yearEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 7, value: value),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  yearGreaterThan(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 7, value: value),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  yearGreaterThanOrEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 7, value: value),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  yearLessThan(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 7, value: value));
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  yearLessThanOrEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 7, value: value),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  yearBetween(int? lower, int? upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 7, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  coverPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 8));
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  coverPathIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 8));
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  coverPathEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 8, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  coverPathGreaterThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 8,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  coverPathGreaterThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 8,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  coverPathLessThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 8, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  coverPathLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 8,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  coverPathBetween(String? lower, String? upper, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 8,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  coverPathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 8,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  coverPathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 8,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  coverPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 8,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  coverPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 8,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  coverPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 8, value: ''),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  coverPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 8, value: ''),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  editedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 9, value: value),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  editedAtGreaterThan(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 9, value: value),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  editedAtGreaterThanOrEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 9, value: value),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  editedAtLessThan(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 9, value: value));
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  editedAtLessThanOrEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 9, value: value),
      );
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterFilterCondition>
  editedAtBetween(DateTime lower, DateTime upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 9, lower: lower, upper: upper),
      );
    });
  }
}

extension TrackEditModelQueryObject
    on QueryBuilder<TrackEditModel, TrackEditModel, QFilterCondition> {}

extension TrackEditModelQuerySortBy
    on QueryBuilder<TrackEditModel, TrackEditModel, QSortBy> {
  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> sortByDeviceId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy>
  sortByDeviceIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> sortByFileName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy>
  sortByFileNameDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> sortBySize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> sortBySizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> sortByTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> sortByTitleDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> sortByArtist({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> sortByArtistDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> sortByAlbum({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> sortByAlbumDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> sortByYear() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> sortByYearDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, sort: Sort.desc);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> sortByCoverPath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy>
  sortByCoverPathDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> sortByEditedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(9);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy>
  sortByEditedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(9, sort: Sort.desc);
    });
  }
}

extension TrackEditModelQuerySortThenBy
    on QueryBuilder<TrackEditModel, TrackEditModel, QSortThenBy> {
  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> thenByDeviceId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy>
  thenByDeviceIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> thenByFileName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy>
  thenByFileNameDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> thenBySize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> thenBySizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> thenByTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> thenByTitleDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> thenByArtist({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> thenByArtistDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> thenByAlbum({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> thenByAlbumDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> thenByYear() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> thenByYearDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, sort: Sort.desc);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> thenByCoverPath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy>
  thenByCoverPathDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy> thenByEditedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(9);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterSortBy>
  thenByEditedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(9, sort: Sort.desc);
    });
  }
}

extension TrackEditModelQueryWhereDistinct
    on QueryBuilder<TrackEditModel, TrackEditModel, QDistinct> {
  QueryBuilder<TrackEditModel, TrackEditModel, QAfterDistinct>
  distinctByDeviceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterDistinct>
  distinctByFileName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterDistinct>
  distinctBySize() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterDistinct> distinctByTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterDistinct>
  distinctByArtist({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(5, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterDistinct> distinctByAlbum({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(6, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterDistinct>
  distinctByYear() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(7);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterDistinct>
  distinctByCoverPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(8, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrackEditModel, TrackEditModel, QAfterDistinct>
  distinctByEditedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(9);
    });
  }
}

extension TrackEditModelQueryProperty1
    on QueryBuilder<TrackEditModel, TrackEditModel, QProperty> {
  QueryBuilder<TrackEditModel, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<TrackEditModel, String, QAfterProperty> deviceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<TrackEditModel, String, QAfterProperty> fileNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<TrackEditModel, int, QAfterProperty> sizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<TrackEditModel, String?, QAfterProperty> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<TrackEditModel, String?, QAfterProperty> artistProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<TrackEditModel, String?, QAfterProperty> albumProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<TrackEditModel, int?, QAfterProperty> yearProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<TrackEditModel, String?, QAfterProperty> coverPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<TrackEditModel, DateTime, QAfterProperty> editedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }
}

extension TrackEditModelQueryProperty2<R>
    on QueryBuilder<TrackEditModel, R, QAfterProperty> {
  QueryBuilder<TrackEditModel, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<TrackEditModel, (R, String), QAfterProperty> deviceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<TrackEditModel, (R, String), QAfterProperty> fileNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<TrackEditModel, (R, int), QAfterProperty> sizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<TrackEditModel, (R, String?), QAfterProperty> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<TrackEditModel, (R, String?), QAfterProperty> artistProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<TrackEditModel, (R, String?), QAfterProperty> albumProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<TrackEditModel, (R, int?), QAfterProperty> yearProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<TrackEditModel, (R, String?), QAfterProperty>
  coverPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<TrackEditModel, (R, DateTime), QAfterProperty>
  editedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }
}

extension TrackEditModelQueryProperty3<R1, R2>
    on QueryBuilder<TrackEditModel, (R1, R2), QAfterProperty> {
  QueryBuilder<TrackEditModel, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<TrackEditModel, (R1, R2, String), QOperations>
  deviceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<TrackEditModel, (R1, R2, String), QOperations>
  fileNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<TrackEditModel, (R1, R2, int), QOperations> sizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<TrackEditModel, (R1, R2, String?), QOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<TrackEditModel, (R1, R2, String?), QOperations>
  artistProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<TrackEditModel, (R1, R2, String?), QOperations> albumProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<TrackEditModel, (R1, R2, int?), QOperations> yearProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<TrackEditModel, (R1, R2, String?), QOperations>
  coverPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<TrackEditModel, (R1, R2, DateTime), QOperations>
  editedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }
}
