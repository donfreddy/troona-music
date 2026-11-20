// ignore_for_file: invalid_use_of_protected_member
import 'package:isar_plus/isar_plus.dart';

/// A playlist as the database stored it before smart playlists: the
/// schema of `PlaylistModel` in v1.7.0, copied from its generated code, to
/// open a database the way an installed app left it.
class LegacyPlaylist {
  int id = 0;
  String playlistId = '';
  String name = '';
  String? artworkPath;
  List<String> trackIds = const [];
}

final legacyPlaylistSchema = IsarGeneratedSchema(
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
  converter: IsarObjectConverter<int, LegacyPlaylist>(
    serialize: _serialize,
    deserialize: _deserialize,
  ),
  getEmbeddedSchemas: () => [],
);

int _serialize(IsarWriter writer, LegacyPlaylist object) {
  IsarCore.writeString(writer, 1, object.playlistId);
  IsarCore.writeString(writer, 2, object.name);
  final artwork = object.artworkPath;
  if (artwork == null) {
    IsarCore.writeNull(writer, 3);
  } else {
    IsarCore.writeString(writer, 3, artwork);
  }
  final list = object.trackIds;
  final listWriter = IsarCore.beginList(writer, 4, list.length);
  for (var i = 0; i < list.length; i++) {
    IsarCore.writeString(listWriter, i, list[i]);
  }
  IsarCore.endList(writer, listWriter);
  return object.id;
}

LegacyPlaylist _deserialize(IsarReader reader) => LegacyPlaylist()
  ..id = IsarCore.readId(reader)
  ..playlistId = IsarCore.readString(reader, 1) ?? ''
  ..name = IsarCore.readString(reader, 2) ?? '';
