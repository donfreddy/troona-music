// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_model.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetPlaylistModelCollection on Isar {
  IsarCollection<int, PlaylistModel> get playlistModels => this.collection();
}

final PlaylistModelSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'PlaylistModel',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'playlistId', type: IsarType.string),
      IsarPropertySchema(name: 'name', type: IsarType.string),
      IsarPropertySchema(name: 'artworkPath', type: IsarType.string),
      IsarPropertySchema(name: 'trackIds', type: IsarType.stringList),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'playlistId',
        properties: ["playlistId"],
        unique: true,
        hash: false,
      ),
    ],
  ),
  converter: IsarObjectConverter<int, PlaylistModel>(
    serialize: serializePlaylistModel,
    deserialize: deserializePlaylistModel,
    deserializeProperty: deserializePlaylistModelProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializePlaylistModel(IsarWriter writer, PlaylistModel object) {
  IsarCore.writeString(writer, 1, object.playlistId);
  IsarCore.writeString(writer, 2, object.name);
  {
    final value = object.artworkPath;
    if (value == null) {
      IsarCore.writeNull(writer, 3);
    } else {
      IsarCore.writeString(writer, 3, value);
    }
  }
  {
    final list = object.trackIds;
    final listWriter = IsarCore.beginList(writer, 4, list.length);
    for (var i = 0; i < list.length; i++) {
      IsarCore.writeString(listWriter, i, list[i]);
    }
    IsarCore.endList(writer, listWriter);
  }
  return object.id;
}

@isarProtected
PlaylistModel deserializePlaylistModel(IsarReader reader) {
  final object = PlaylistModel();
  object.id = IsarCore.readId(reader);
  object.playlistId = IsarCore.readString(reader, 1) ?? '';
  object.name = IsarCore.readString(reader, 2) ?? '';
  object.artworkPath = IsarCore.readString(reader, 3);
  {
    final length = IsarCore.readList(reader, 4, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        object.trackIds = const <String>[];
      } else {
        final list = List<String>.filled(length, '', growable: true);
        for (var i = 0; i < length; i++) {
          list[i] = IsarCore.readString(reader, i) ?? '';
        }
        IsarCore.freeReader(reader);
        object.trackIds = list;
      }
    }
  }
  return object;
}

@isarProtected
dynamic deserializePlaylistModelProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readString(reader, 2) ?? '';
    case 3:
      return IsarCore.readString(reader, 3);
    case 4:
      {
        final length = IsarCore.readList(reader, 4, IsarCore.readerPtrPtr);
        {
          final reader = IsarCore.readerPtr;
          if (reader.isNull) {
            return const <String>[];
          } else {
            final list = List<String>.filled(length, '', growable: true);
            for (var i = 0; i < length; i++) {
              list[i] = IsarCore.readString(reader, i) ?? '';
            }
            IsarCore.freeReader(reader);
            return list;
          }
        }
      }
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _PlaylistModelUpdate {
  bool call({
    required int id,
    String? playlistId,
    String? name,
    String? artworkPath,
  });
}

class _PlaylistModelUpdateImpl implements _PlaylistModelUpdate {
  const _PlaylistModelUpdateImpl(this.collection);

  final IsarCollection<int, PlaylistModel> collection;

  @override
  bool call({
    required int id,
    Object? playlistId = ignore,
    Object? name = ignore,
    Object? artworkPath = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (playlistId != ignore) 1: playlistId as String?,
            if (name != ignore) 2: name as String?,
            if (artworkPath != ignore) 3: artworkPath as String?,
          },
        ) >
        0;
  }
}

sealed class _PlaylistModelUpdateAll {
  int call({
    required List<int> id,
    String? playlistId,
    String? name,
    String? artworkPath,
  });
}

class _PlaylistModelUpdateAllImpl implements _PlaylistModelUpdateAll {
  const _PlaylistModelUpdateAllImpl(this.collection);

  final IsarCollection<int, PlaylistModel> collection;

  @override
  int call({
    required List<int> id,
    Object? playlistId = ignore,
    Object? name = ignore,
    Object? artworkPath = ignore,
  }) {
    return collection.updateProperties(id, {
      if (playlistId != ignore) 1: playlistId as String?,
      if (name != ignore) 2: name as String?,
      if (artworkPath != ignore) 3: artworkPath as String?,
    });
  }
}

extension PlaylistModelUpdate on IsarCollection<int, PlaylistModel> {
  _PlaylistModelUpdate get update => _PlaylistModelUpdateImpl(this);

  _PlaylistModelUpdateAll get updateAll => _PlaylistModelUpdateAllImpl(this);
}

sealed class _PlaylistModelQueryUpdate {
  int call({String? playlistId, String? name, String? artworkPath});
}

class _PlaylistModelQueryUpdateImpl implements _PlaylistModelQueryUpdate {
  const _PlaylistModelQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<PlaylistModel> query;
  final int? limit;

  @override
  int call({
    Object? playlistId = ignore,
    Object? name = ignore,
    Object? artworkPath = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (playlistId != ignore) 1: playlistId as String?,
      if (name != ignore) 2: name as String?,
      if (artworkPath != ignore) 3: artworkPath as String?,
    });
  }
}

extension PlaylistModelQueryUpdate on IsarQuery<PlaylistModel> {
  _PlaylistModelQueryUpdate get updateFirst =>
      _PlaylistModelQueryUpdateImpl(this, limit: 1);

  _PlaylistModelQueryUpdate get updateAll =>
      _PlaylistModelQueryUpdateImpl(this);
}

class _PlaylistModelQueryBuilderUpdateImpl
    implements _PlaylistModelQueryUpdate {
  const _PlaylistModelQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<PlaylistModel, PlaylistModel, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? playlistId = ignore,
    Object? name = ignore,
    Object? artworkPath = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (playlistId != ignore) 1: playlistId as String?,
        if (name != ignore) 2: name as String?,
        if (artworkPath != ignore) 3: artworkPath as String?,
      });
    } finally {
      q.close();
    }
  }
}

extension PlaylistModelQueryBuilderUpdate
    on QueryBuilder<PlaylistModel, PlaylistModel, QOperations> {
  _PlaylistModelQueryUpdate get updateFirst =>
      _PlaylistModelQueryBuilderUpdateImpl(this, limit: 1);

  _PlaylistModelQueryUpdate get updateAll =>
      _PlaylistModelQueryBuilderUpdateImpl(this);
}

extension PlaylistModelQueryFilter
    on QueryBuilder<PlaylistModel, PlaylistModel, QFilterCondition> {
  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition> idEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  idGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  idGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition> idLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 0, value: value));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  idLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition> idBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 0, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  playlistIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  playlistIdGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  playlistIdGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  playlistIdLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  playlistIdLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  playlistIdBetween(String lower, String upper, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  playlistIdStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  playlistIdEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  playlistIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  playlistIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  playlistIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  playlistIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  nameGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  nameGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  nameLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  nameLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  nameStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  nameEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  nameContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition> nameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  artworkPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 3));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  artworkPathIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 3));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  artworkPathEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  artworkPathGreaterThan(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  artworkPathGreaterThanOrEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  artworkPathLessThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  artworkPathLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  artworkPathBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  artworkPathStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  artworkPathEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  artworkPathContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  artworkPathMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  artworkPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  artworkPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  trackIdsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 4, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  trackIdsElementGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  trackIdsElementGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  trackIdsElementLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 4, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  trackIdsElementLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  trackIdsElementBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  trackIdsElementStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  trackIdsElementEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  trackIdsElementContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  trackIdsElementMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  trackIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 4, value: ''),
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  trackIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 4, value: ''),
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  trackIdsIsEmpty() {
    return not().trackIdsIsNotEmpty();
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
  trackIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 4, value: null),
      );
    });
  }
}

extension PlaylistModelQueryObject
    on QueryBuilder<PlaylistModel, PlaylistModel, QFilterCondition> {}

extension PlaylistModelQuerySortBy
    on QueryBuilder<PlaylistModel, PlaylistModel, QSortBy> {
  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy> sortByPlaylistId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
  sortByPlaylistIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy> sortByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy> sortByNameDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy> sortByArtworkPath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
  sortByArtworkPathDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }
}

extension PlaylistModelQuerySortThenBy
    on QueryBuilder<PlaylistModel, PlaylistModel, QSortThenBy> {
  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy> thenByPlaylistId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
  thenByPlaylistIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy> thenByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy> thenByNameDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy> thenByArtworkPath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
  thenByArtworkPathDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }
}

extension PlaylistModelQueryWhereDistinct
    on QueryBuilder<PlaylistModel, PlaylistModel, QDistinct> {
  QueryBuilder<PlaylistModel, PlaylistModel, QAfterDistinct>
  distinctByPlaylistId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterDistinct> distinctByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterDistinct>
  distinctByArtworkPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterDistinct>
  distinctByTrackIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4);
    });
  }
}

extension PlaylistModelQueryProperty1
    on QueryBuilder<PlaylistModel, PlaylistModel, QProperty> {
  QueryBuilder<PlaylistModel, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<PlaylistModel, String, QAfterProperty> playlistIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<PlaylistModel, String, QAfterProperty> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<PlaylistModel, String?, QAfterProperty> artworkPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<PlaylistModel, List<String>, QAfterProperty> trackIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}

extension PlaylistModelQueryProperty2<R>
    on QueryBuilder<PlaylistModel, R, QAfterProperty> {
  QueryBuilder<PlaylistModel, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<PlaylistModel, (R, String), QAfterProperty>
  playlistIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<PlaylistModel, (R, String), QAfterProperty> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<PlaylistModel, (R, String?), QAfterProperty>
  artworkPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<PlaylistModel, (R, List<String>), QAfterProperty>
  trackIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}

extension PlaylistModelQueryProperty3<R1, R2>
    on QueryBuilder<PlaylistModel, (R1, R2), QAfterProperty> {
  QueryBuilder<PlaylistModel, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<PlaylistModel, (R1, R2, String), QOperations>
  playlistIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<PlaylistModel, (R1, R2, String), QOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<PlaylistModel, (R1, R2, String?), QOperations>
  artworkPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<PlaylistModel, (R1, R2, List<String>), QOperations>
  trackIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}
