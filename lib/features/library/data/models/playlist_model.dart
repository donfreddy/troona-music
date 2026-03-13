import 'package:isar_plus/isar_plus.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';

@collection
class PlaylistModel {
  Id? id;
  late String playlistId;
  late String name;
  String? artworkPath;

  Playlist toEntity() => Playlist(id: playlistId, name: name, artworkPath: artworkPath);
}
